FROM selenium/standalone-chrome

USER root

RUN pip install --upgrade pip && \
    pip install \
        selenium \
        webdriver-manager \
        pytest \
        pytest-xdist \
        pyautogui
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

USER seluser
