ARG EMSCRIPTEN_VERSION=1.39.8-upstream
FROM emscripten/emsdk:${EMSCRIPTEN_VERSION}
LABEL maintainer "Tasuku Suzuki <stasuku@gmail.com>"

ARG QT5_REPOSITORY=git://code.qt.io
ARG QT5_BRANCH=v5.15.0
ARG QT5_MODULES=qtbase,qtdeclarative
ARG QTWASMSDK=https://github.com/task-jp/qtwasmsdk

RUN echo ${QT5_REPOSITORY}

RUN echo "## Cloning Qt source code for local server" \
    && mkdir -p /root/qt && cd /root/qt \
    && git clone ${QT5_REPOSITORY}/qt/qt5 --branch ${QT5_BRANCH} > /dev/null 2>&1 \
    && cd qt5 \
    && ./init-repository --module-subset=qtbase > /dev/null 2>&1

RUN echo "## Building Qt for local server" \
    && mkdir -p /root/qt/local && cd /root/qt/local \
    && ../qt5/configure -opensource -confirm-license -prefix /opt/qt/local -make libs -no-gui -skip qtdeclarative > /dev/null 2>&1 \
    && make -j$(nproc) > /dev/null 2>&1 \
    && make -j$(nproc) install > /dev/null 2>&1

RUN echo "## Building QtHttpServer" \
    && mkdir -p /root/qthttpserver && cd /root/qthttpserver \
    && git clone ${QT5_REPOSITORY}/qt-labs/qthttpserver --recursive > /dev/null 2>&1 \
    && mkdir /root/qthttpserver/build && cd /root/qthttpserver/build \
    && /opt/qt/local/bin/qmake ../qthttpserver/ > /dev/null 2>&1 \
    && make -j$(nproc) > /dev/null 2>&1 \
    && make -j$(nproc) install > /dev/null 2>&1

RUN echo "## Cloning Qt source code for wasm" \
    && cd /root/qt/qt5 \
    && ./init-repository -f --module-subset=${QT5_MODULES} > /dev/null 2>&1

RUN echo "## Building Qt for wasm" \
    && mkdir -p /root/qt/wasm && cd /root/qt/wasm \
    && ../qt5/configure -opensource -confirm-license -prefix /opt/qt/wasm -xplatform wasm-emscripten -make libs > /dev/null 2>&1 \
    && make -j$(nproc) > /dev/null 2>&1 \
    && make -j$(nproc) install > /dev/null 2>&1

RUN echo "## Building webserver" \
    && mkdir -p /root/qtwasmsdk \
    && cd /root/qtwasmsdk \
    && git clone ${QTWASMSDK} \
    && mkdir -p build/webserver \
    && cd build/webserver \
    && /opt/qt/local/bin/qmake ../../qtwasmsdk/webserver \
    && make -j$(nproc) \
    && make -j$(nproc) install

RUN echo "## Cleaning up" \
    && rm -rf /root/qt*

ENV PATH="/opt/qt/wasm/bin:/opt/qt/local/bin:${PATH}"

VOLUME ["/app"]
EXPOSE 8080

WORKDIR /app
COPY entrypoint /opt/qt/
RUN chmod 755 /opt/qt/entrypoint
ENTRYPOINT ["/opt/qt/entrypoint"]
CMD qmake -makefile && make -j$(nproc) && echo "Starting web server" && webserver || echo "I'm sorry."
