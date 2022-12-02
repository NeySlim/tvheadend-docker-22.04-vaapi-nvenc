FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

ENV HOME="/config"

#RUN echo "LIBVA_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri" >> /etc/environment
#RUN echo "LIBVA_DRIVER_NAME=iHD" >> /etc/environment


#Packages needed for compilation
RUN apt update && apt -y full-upgrade && apt -y --no-install-recommends install \
						software-properties-common \
						add-apt-key \
						gnupg \
						python3 \
						python-is-python3 \
						git \
						xmltv \
						curl \
						jq \
						python3-requests \
						file \
						intel-media-va-driver-non-free \
						vainfo \
						build-essential \
						autoconf \
						automake \
						git \
						pkg-config \
						bzip2 \
						wget \
						gettext \
						cmake \
						make \
						libtool \
						patch \
						libdvbcsa1 \
						liburiparser1 \
						libpcre3 \
						libdrm-intel1 \
						libdrm2 \
						cuda-compat-11-4
#						ffmpeg


#Compilation libraries
RUN apt -y install --no-install-recommends 	libssl-dev \
											libmfx-dev \
											libfdk-aac-dev \
											libavahi-client-dev \
											zlib1g-dev \
											libswscale-dev \
											libdvbcsa-dev \
											libva-dev \
											libvpx-dev \
											libpcre3-dev \
											libopus-dev \
											liburiparser-dev \
											libdrm-dev \
											libopus-dev 
											
											
											

RUN \
 echo "**** compile tvheadend ****" && \
 TVHEADEND_COMMIT=$(curl -sX GET https://api.github.com/repos/tvheadend/tvheadend/commits/master | jq -r '. | .sha'); \
 git clone https://github.com/tvheadend/tvheadend.git /tmp/tvheadend && cd /tmp/tvheadend && git checkout ${TVHEADEND_COMMIT} 

COPY patches/ffmpeg-4.4.3.patch /tmp/tvheadend

 RUN cd /tmp/tvheadend && patch Makefile.ffmpeg ffmpeg-4.4.3.patch && \
  ./configure \
    --enable-libfdkaac \
	--enable-libopus \
	--enable-libvorbis \
	--enable-libvpx \
	--enable-libx264 \
	--enable-libx265 \
	--enable-vaapi\
	--enable-libmfx \
	--enable-libav \
	--enable-nvenc \
	--enable-pngquant \
	--enable-trace \
	--infodir=/usr/share/info \
	--localstatedir=/var \
	--mandir=/usr/share/man \
	--prefix=/usr \
	--python=python3 \
	--sysconfdir=/config && \
 make -j 14 && \
 make install

RUN apt -y purge 	libssl-dev \
					libmfx-dev \
					libfdk-aac-dev \
					libavahi-client-dev \
					zlib1g-dev \
					libswscale-dev \
					libdvbcsa-dev \
					libva-dev \
					libvpx-dev \
					libpcre3-dev \
					libopus-dev \
					liburiparser-dev \
					libdrm-dev \
					libopus-dev \
					nvidia-cuda-dev
					
#RUN apt -y --no-install-recommends install nvidia-driver-515-server


RUN apt clean
RUN rm -rf /tmp* && groupadd -r -g 1000 hts && useradd -r -u 1000 -g 1000 hts
COPY starttvh /usr/local/bin/.
RUN chmod +x /usr/local/bin/starttvh


EXPOSE 9981 9982
VOLUME /config
#WORKDIR 

ENTRYPOINT ["starttvh"]
CMD ["/usr/bin/tvheadend","-c","/config","-C","-p","/run/tvheadend.pid", "-l", "/var/log/tvheadend"]
