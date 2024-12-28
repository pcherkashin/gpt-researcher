# Stage 1: Browser and build tools installation
FROM python:3.11.4-slim-bullseye AS install-browser

# Use a reliable mirror and fix dependency issues
RUN sed -i.bak 's|http://deb.debian.org|http://ftp.us.debian.org|g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    chromium chromium-driver firefox-esr wget build-essential && \
    wget https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-linux64.tar.gz && \
    tar -xvzf geckodriver-v0.33.0-linux64.tar.gz && \
    chmod +x geckodriver && \
    mv geckodriver /usr/local/bin/ && \
    rm geckodriver-v0.33.0-linux64.tar.gz && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*  # Clean up apt lists

# Verify installed versions
RUN chromium --version && chromedriver --version && firefox --version && geckodriver --version

# Stage 2: Python dependencies installation
FROM install-browser AS gpt-researcher-install

ENV PIP_ROOT_USER_ACTION=ignore
WORKDIR /usr/src/app

# Copy and install Python dependencies in a single layer
COPY ./requirements.txt ./requirements.txt
COPY ./multi_agents/requirements.txt ./multi_agents/requirements.txt

RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir -r multi_agents/requirements.txt

# Stage 3: Final stage with non-root user and app
FROM gpt-researcher-install AS gpt-researcher

# Create a non-root user for security
RUN useradd -ms /bin/bash gpt-researcher && \
    chown -R gpt-researcher:gpt-researcher /usr/src/app

USER gpt-researcher
WORKDIR /usr/src/app

# Copy the application files with proper ownership
COPY --chown=gpt-researcher:gpt-researcher ./ ./

# Expose the application's port
EXPOSE 8000

# Define the default command to run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]