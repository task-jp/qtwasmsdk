#include <QtHttpServer>

QByteArray readBinaryFile(const QString &fileName) {
    QByteArray ret;
    QFile file(fileName);
    if (file.open(QFile::ReadOnly)) {
        ret = file.readAll();
        file.close();
    }
    return ret;
}

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);

    QString baseName;
    QDir dir = QDir::current();
    for (const QString &wasm : dir.entryList({"*.wasm"}, QDir::Files, QDir::Time)) {
        baseName = QFileInfo(dir.absoluteFilePath(wasm)).baseName();
        break;
    }

    if (baseName.isNull()) {
        qWarning() << "no *.wasm found";
        return -1;
    }

    QString fileName = QStringLiteral("%3/%1.%2").arg(baseName);

    QHttpServer server;
    server.route("/", "GET", [&]() {
        return readBinaryFile(fileName.arg("html", "."));
    });
    server.route(fileName.arg("js", ""), "GET", [&]() {
        return readBinaryFile(fileName.arg("js", "."));
    });
    server.route(fileName.arg("wasm", ""), "GET", [&]() {
        return readBinaryFile(fileName.arg("wasm", "."));
    });
    server.route("/qtloader.js", "GET", [&]() {
        return readBinaryFile("qtloader.js");
    });
    server.route("/qtlogo.svg", "GET", [&]() {
        return readBinaryFile("qtlogo.svg");
    });
    server.listen(QHostAddress::Any, 8080);

    return app.exec();
}
