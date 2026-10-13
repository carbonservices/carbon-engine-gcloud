#ifndef SERVER_CONFIG_H
#define SERVER_CONFIG_H

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QProcessEnvironment>
#include <QString>

#include "constants/CommonConstants.h"

const int kEmbeddingDim = ServerDefaults::DefaultEmbeddingDim;
const quint16 kDefaultPort = ServerDefaults::DefaultPort;

const QString kDatabaseFilePath = ServerDefaults::DefaultDatabaseName;
const QString kDefaultGenerationModel = Models::LocalGemmaFile;
const QString kDefaultEmbeddingModel = Models::LocalBgeEmbeddingFile;

inline QString resolveModelPath(const QString &name, const QString &fallback)
{
    QString envVal = QProcessEnvironment::systemEnvironment().value(name);
    if (!envVal.isEmpty()) {
        return envVal;
    }
    if (QFile::exists(fallback)) {
        return fallback;
    }
    QString appRelative = QDir(QCoreApplication::applicationDirPath()).filePath(fallback);
    if (QFile::exists(appRelative)) {
        return appRelative;
    }
    QString parentRelative = QDir(QCoreApplication::applicationDirPath() + "/../../..").filePath(fallback);
    if (QFile::exists(parentRelative)) {
        return parentRelative;
    }
    return fallback;
}

const QString kGenerationModelPath = resolveModelPath("CARBON_ENGINE_GEN_MODEL", kDefaultGenerationModel);
const QString kEmbeddingModelPath = resolveModelPath("CARBON_ENGINE_EMBD_MODEL", kDefaultEmbeddingModel);

#endif // SERVER_CONFIG_H
