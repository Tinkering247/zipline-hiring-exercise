# Multi-stage build for minimal image size
FROM ruby:3.2-alpine AS base

# Install only essential runtime dependencies
RUN apk add --no-cache \
    tzdata

WORKDIR /app

# Copy application files
COPY grouper.rb .

# Make the script executable
RUN chmod +x grouper.rb

# Create a non-root user for security
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

USER appuser

# Set the entrypoint
ENTRYPOINT ["ruby", "grouper.rb"]

# Default command shows usage
CMD []
