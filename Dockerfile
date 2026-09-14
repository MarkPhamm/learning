# Base image
FROM python:3.12-slim

# Install dependencies - refreshes Debian's package index and installs git
RUN apt-get update -yqq && \
    apt-get install -yqq \
    git \
    gcc

# Upgrade pip
RUN pip install --upgrade pip

# Copy requirements.txt and install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Create app directory and copy the current directory contents into it
RUN mkdir -p /app 
COPY ./ /app/

# Make all files in the app directory executable
RUN chmod 777 -R /app

# Set the working directory to /app
WORKDIR /app