FROM openwrt/imagebuilder:x86-64-24.10.0
USER root
COPY config /build/config
COPY diy-part.sh /build/diy-part.sh
RUN chmod +x /build/diy-part.sh
