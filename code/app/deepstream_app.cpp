#include <gst/gst.h>
#include <glib.h>
#include <iostream>
#include <cuda_runtime_api.h>
#include "gstnvdsmeta.h"
#include "nvds_yml_parser.h"



#define MAX_DISPLAY_LEN 64

#define PGIE_CLASS_ID_VEHICLE 0
#define PGIE_CLASS_ID_PERSON 2

/* The muxer output resolution must be set if the input streams will be of
 * different resolution. The muxer will scale all the input frames to this
 * resolution. */
#define MUXER_OUTPUT_WIDTH 1920
#define MUXER_OUTPUT_HEIGHT 1080

/* Muxer batch formation timeout, for e.g. 40 millisec. Should ideally be set
 * based on the fastest source's framerate. */
#define MUXER_BATCH_TIMEOUT_USEC 40000

gint frame_number = 0;
gchar pgie_classes_str[4][32] = { "Vehicle", "TwoWheeler", "Person",
  "Roadsign"
};

namespace callbacks {
GstPadProbeReturn 
  meta_parse(GstPad *pad, GstPadProbeInfo *info, gpointer u_data)
  {
      GstBuffer *buf = (GstBuffer *)info->data;
      guint num_rects = 0;
      NvDsObjectMeta *obj_meta = NULL;
      guint vehicle_count = 0;
      guint person_count = 0;
      NvDsMetaList *l_frame = NULL;
      NvDsMetaList *l_obj = NULL;
      NvDsDisplayMeta *display_meta = NULL;

      NvDsBatchMeta *batch_meta = gst_buffer_get_nvds_batch_meta(buf);

      /* ============================ 
       * parser from deepstream_test1_app.c */
      for (l_frame = batch_meta->frame_meta_list; l_frame != NULL;
        l_frame = l_frame->next) {
          NvDsFrameMeta *frame_meta = (NvDsFrameMeta *) (l_frame->data);
          int offset = 0;
          for (l_obj = frame_meta->obj_meta_list; l_obj != NULL;
                  l_obj = l_obj->next) {
              obj_meta = (NvDsObjectMeta *) (l_obj->data);
              if (obj_meta->class_id == PGIE_CLASS_ID_VEHICLE) {
                  vehicle_count++;
                  num_rects++;
              }
              if (obj_meta->class_id == PGIE_CLASS_ID_PERSON) {
                  person_count++;
                  num_rects++;
              }
          }
          display_meta = nvds_acquire_display_meta_from_pool(batch_meta);
          NvOSD_TextParams *txt_params  = &display_meta->text_params[0];
          display_meta->num_labels = 1;
          txt_params->display_text = static_cast<char*>(g_malloc0 (MAX_DISPLAY_LEN));
          offset = snprintf(txt_params->display_text, MAX_DISPLAY_LEN, "Person = %d ", person_count);
          offset = snprintf(txt_params->display_text + offset , MAX_DISPLAY_LEN, "Vehicle = %d ", vehicle_count);

          /* Now set the offsets where the string should appear */
          txt_params->x_offset = 10;
          txt_params->y_offset = 12;

          /* Font , font-color and font-size */
          txt_params->font_params.font_name = const_cast<char*>(std::string("Serif").c_str());
          txt_params->font_params.font_size = 10;
          txt_params->font_params.font_color.red = 1.0;
          txt_params->font_params.font_color.green = 1.0;
          txt_params->font_params.font_color.blue = 1.0;
          txt_params->font_params.font_color.alpha = 1.0;

          /* Text background color */
          txt_params->set_bg_clr = 1;
          txt_params->text_bg_clr.red = 0.0;
          txt_params->text_bg_clr.green = 0.0;
          txt_params->text_bg_clr.blue = 0.0;
          txt_params->text_bg_clr.alpha = 1.0;

          nvds_add_display_meta_to_frame(frame_meta, display_meta);
      }

      g_print ("Frame Number = %d Number of objects = %d "
              "Vehicle Count = %d Person Count = %d\n",
              frame_number, num_rects, vehicle_count, person_count);
      frame_number++;



      return GST_PAD_PROBE_OK;
  }
}




static gboolean
bus_call (GstBus * bus, GstMessage * msg, gpointer data)
{
  GMainLoop *loop = (GMainLoop *) data;
  switch (GST_MESSAGE_TYPE (msg)) {
    case GST_MESSAGE_EOS:
      g_print ("End of stream\n");
      g_main_loop_quit (loop);
      break;
    case GST_MESSAGE_ERROR:{
      gchar *debug;
      GError *error;
      gst_message_parse_error (msg, &error, &debug);
      g_printerr ("ERROR from element %s: %s\n",
          GST_OBJECT_NAME (msg->src), error->message);
      if (debug)
        g_printerr ("Error details: %s\n", debug);
      g_free (debug);
      g_error_free (error);
      g_main_loop_quit (loop);
      break;
    }
    default:
      break;
  }
  return TRUE;
}


int
main (int   argc, char *argv[])
{
  GMainLoop *loop;
  GstElement *pipeline = NULL; 

  /* Define elements */
  GstElement *source = NULL, *h264parse = NULL,       
	     *decoder = NULL, *streammux = NULL,  *pgie = NULL, *tracker = NULL, *queue = NULL,
	     *nvvidconv = NULL, *nvosd = NULL, *nvvidconv2 = NULL,
	     *encoder = NULL, *sink = NULL;
  // Pipeline: source -> h264parse -> decoder -> streammux -> pgie -> tracker -> queue -> nvvidconv -> nvosd
  // nvvidconv2 -> encoder -> filesink

  GstBus *bus;
  guint bus_watch_id;

  /*Nvidia property*/
  int current_device = -1;
  cudaGetDevice(&current_device);
  struct cudaDeviceProp prop;
  cudaGetDeviceProperties(&prop, current_device);


  /* Initialization */
  gst_init (&argc, &argv);
  loop = g_main_loop_new (NULL, FALSE);

  /* Check input arguments */
  if (argc != 3)
  {
    g_printerr ("Usage: %s <input H264 filename> <output H264 filename>\n", argv[0]);
    for ( int i = 0; i < argc; i++ )
    {
      g_print("Arg %d: %s\n", i, argv[i] );
    }
    return -1;
  }


  /* Create gstreamer elements */
  pipeline = gst_pipeline_new ("save-video-with-bound-box"); //Create Pipeline element that will form a connection of other elements
  source = gst_element_factory_make ("filesrc", "file-source");  // file source
  h264parse = gst_element_factory_make ("h264parse", "h264-parser");  //Since the data format in the output file is elementary h264 stream, we need a h264parser
  decoder = gst_element_factory_make ("nvv4l2decoder", "nv-decoder");  //Use nvdec_h264 for hardware accelerated decode on GPU 
  streammux = gst_element_factory_make ("nvstreammux", "stream-muxer"); //Create nvstreammux instance to form batches from one or more sources.
  pgie = gst_element_factory_make ("nvinfer","primary-nvinference-engine"); //Use nvinfer to run inferencing on decoder's output, behaviour of inferencing is set through config file

  tracker = gst_element_factory_make ("nvtracker","identity-tracker"); //Use nvtracker to identify object on nvinfer's output, behaviour of tracking is set through config file
  queue = gst_element_factory_make ("queue", "cache"); //Create a queue for caching output
  nvvidconv = gst_element_factory_make ("nvvideoconvert", "nvvideo-converter"); //Use convertor to convert from NV12 to RGBA as required by nvosd 
  nvosd = gst_element_factory_make ("nvdsosd", "nv-onscreendisplay"); //Create OSD to draw on the converted RGBA buffer
  nvvidconv2 = gst_element_factory_make ("nvvideoconvert", "nvvideo-converter-2"); //Use convertor to convert from NV12 to RGBA as required by nvosd 
  encoder = gst_element_factory_make ("nvv4l2h264enc", "nvv4l2-encoder");//Use nvenc_h264 for hardware accelerated encode on GPU
  sink = gst_element_factory_make ("filesink","output-file"); // save video to file

  if (!pipeline || !source || !h264parse || !decoder || !streammux || !pgie || !tracker || !queue || !nvvidconv || !nvosd || !nvvidconv2 || !encoder || !sink )
  {
    g_printerr ("One element could not be created. Exiting.\n");
    return -1;
  }




  /* Set up the pipeline */

  /* we set the input filename to the source element */
  g_object_set (G_OBJECT (source), "location", argv[1], NULL);
  g_object_set (G_OBJECT (sink), "location", argv[2], NULL);

  /* setting streammux */
  g_object_set (G_OBJECT (streammux), "batch-size", 1, NULL);
  g_object_set (G_OBJECT (streammux), "width", MUXER_OUTPUT_WIDTH, "height", MUXER_OUTPUT_HEIGHT, "batched-push-timeout", MUXER_BATCH_TIMEOUT_USEC, NULL);


  /* we set properties of pgie and tracker */
  /* setting nvinfer*/
  if (getenv ("NVINFER_YML"))
  {
    g_print ("NVINFER_YML=%s\n", getenv ("NVINFER_YML") );
    g_object_set (G_OBJECT (pgie), "config-file-path", getenv("NVINFER_YML"), NULL);
  }
  else
  {
    g_print ("Use default NVINFER_YML=/code/config_infer_primary.yml" );
    g_object_set (G_OBJECT (pgie), "config-file-path","/code/config_infer_primary.yml", NULL);
  }
  /* setting tracker*/
  if ( getenv ("TRACKER_YML") && getenv ("TRACKER_LIB") )
  {
    g_print ("TRACKER_YML=%s\n", getenv("TRACKER_YML") );
    g_print ("TRACKER_LIB=%s\n", getenv("TRACKER_LIB") );
    g_object_set (G_OBJECT (tracker), "ll-config-file", getenv("TRACKER_YML"), NULL);
    g_object_set (G_OBJECT (tracker), "ll-lib-file", getenv("TRACKER_LIB"), NULL);
  }
  else
  {
    g_print ("Use default TRACKER_YML=/opt/nvidia/deepstream/deepstream-6.1/samples/configs/deepstream-app/config_tracker_NvDCF_perf.yml" );
    g_print ("Use default TRACKER_LIB=/opt/nvidia/deepstream/deepstream/lib/libnvds_nvmultiobjecttracker.so");
    g_object_set (G_OBJECT (tracker), "ll-config-file","/opt/nvidia/deepstream/deepstream-6.1/samples/configs/deepstream-app/config_tracker_NvDCF_perf.yml" , NULL);
    g_object_set (G_OBJECT (tracker), "ll-lib-file", "/opt/nvidia/deepstream/deepstream/lib/libnvds_nvmultiobjecttracker.so" , NULL);
  }


  /* we add a message handler */
  bus = gst_pipeline_get_bus (GST_PIPELINE (pipeline) );
  bus_watch_id = gst_bus_add_watch (bus, bus_call, loop);
  gst_object_unref (bus);

  /* we add all elements into the pipeline */
  // TODO modify for integrated graphics? 
  // Currently assume discrete graphics exist
  gst_bin_add_many (GST_BIN (pipeline),
      source, h264parse, decoder, streammux, pgie,tracker,
      nvvidconv, nvosd, 
      queue, nvvidconv2, encoder,
      sink, NULL);


  // separate into two segments, used for dynamic pad in original test
  // it's done this way probably because the streammux needs to have a new sink requested
  GstPad *srcpad, *sinkpad; 
  gchar pad_name_src[16] = "src";
  gchar pad_name_sink[16] = "sink_0";

  sinkpad = gst_element_get_request_pad (streammux, pad_name_sink); //sinkpad starts from streammux, dynamic pad? 
  if (!sinkpad) {
    g_printerr ("Streamux request sink pad failed. Exiting.\n");
    return -1;
  }

  srcpad = gst_element_get_static_pad (decoder, pad_name_src);
  if (!srcpad) {
    g_printerr ("Decoder request src pad failed. Exiting.\n");
    return -1;
  }


  if (gst_pad_link (srcpad, sinkpad) != GST_PAD_LINK_OK) {
      g_printerr ("Failed to link decoder to stream muxer. Exiting.\n");
      return -1;
  }

  gst_object_unref (sinkpad);
  gst_object_unref (srcpad);

  /* we link the elements together */
  // Pipeline: source -> h264parse -> decoder -> 
  //           streammux -> pgie -> tracker -> queue -> nvvidconv -> nvosd -> nvvidconv2 -> encoder -> filesink
  if (!gst_element_link_many (source, h264parse, decoder, NULL)) {
    g_printerr ("Elements could not be linked: 1. Exiting.\n");
    return -1;
  }
  if (!gst_element_link_many (streammux, pgie, tracker,
      nvvidconv, nvosd, queue, nvvidconv2,encoder,sink, NULL)) {
    g_printerr ("Elements could not be linked: 2. Exiting.\n");
    return -1;
  }

  /* Add meta data here TODO */
  GstPad *probe_pad = NULL;
  std::string pad_name = "sink";
  probe_pad = gst_element_get_static_pad( nvosd, pad_name.c_str());
  gst_pad_add_probe(probe_pad, GST_PAD_PROBE_TYPE_BUFFER, &callbacks::meta_parse, NULL, NULL);

  /* Set the pipeline to "playing" state */
  g_print ("Using file: %s\n", argv[1]);
  gst_element_set_state (pipeline, GST_STATE_PLAYING);

  /* Wait till pipeline encounters an error or EOS */
  g_print ("Running...\n");
  g_main_loop_run (loop);

  /* Out of the main loop, clean up nicely */
  g_print ("Returned, stopping playback\n");
  gst_element_set_state (pipeline, GST_STATE_NULL);
  g_print ("Deleting pipeline\n");
  gst_object_unref (GST_OBJECT (pipeline));
  g_source_remove (bus_watch_id);
  g_main_loop_unref (loop);
  return 0;
}

