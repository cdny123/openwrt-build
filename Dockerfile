# Use specific tag to avoid breaking changes
FROM openwrt/imagebuilder:x86-64-24.10.0

# Switch to root user
USER root

# Copy configuration and scripts
COPY config /build/config
COPY diy-part.sh /build/diy-part.sh

# Grant execute permission and run the script in a single layer
RUN chmod +x /build/diy-part.sh && /build/diy-part.sh

# Optional: Add any cleanup commands here if needed

# Document the Dockerfile with comments
# This Dockerfile sets up the OpenWRT image builder with custom configuration
