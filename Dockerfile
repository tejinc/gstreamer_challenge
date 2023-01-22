FROM rad_challenge

ADD ./code /code
WORKDIR /code/app
RUN ls
RUN make
ENTRYPOINT ["/code/app/deepstream-app"]
#CMD ["/code/app/deepstream-app"]
