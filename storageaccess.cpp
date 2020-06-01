#include "storageaccess.h"

#if defined(Q_OS_ANDROID)
#include <QtAndroidExtras>
#include <QtAndroidExtras/QAndroidJniObject>
#include <jni.h>
#endif

const static int RESULT_OK = -1;
const static int RESULT_CANCELED = 0;

StorageAccess * StorageAccess::m_pInstance = 0;

StorageAccess::StorageAccess(QObject *parent) : QObject(parent)
{
    m_pInstance = this;
}

StorageAccess * StorageAccess::getInstance()
{
    if (!m_pInstance)
    {
        m_pInstance = new StorageAccess();
    }

    return m_pInstance;
}

void StorageAccess::onFileOpenActivityResult(int resultCode, const QString & fileUri, const QString & decodedFileUri, const QByteArray & fileContent)
{
    if(resultCode == RESULT_OK)
    {
        emit openFileContentReceived(fileUri, decodedFileUri, fileContent);
    }
    else if(resultCode == RESULT_CANCELED)
    {
        emit openFileCanceled();
    }
    else
    {
        emit openFileError(QString("unexpected result code %1").arg(resultCode));
    }
}

void StorageAccess::onFileCreateActivityResult(int resultCode, const QString & fileUri, const QString & decodedFileUri)
{
    if(resultCode == RESULT_OK)
    {
        emit createFileReceived(fileUri, decodedFileUri);
    }
    else if(resultCode == RESULT_CANCELED)
    {
        emit openFileCanceled();
    }
    else
    {
        emit openFileError(QString("unexpected result code %1").arg(resultCode));
    }
}

void StorageAccess::openFile()
{
#if defined(Q_OS_ANDROID)
    jboolean ok = QAndroidJniObject::callStaticMethod<jboolean>("de/mneuroth/utils/QStorageAccess",
                                              "openFile",
                                              "()Z");
    if(!ok)
    {
        emit openFileError(tr("Error: can not call java method openFile()"));
    }
#endif
}

#if defined(Q_OS_ANDROID)
// http://pavelk.ru/qt-android-jni-preobrazovanie-qbytearray-v-jbytearray
jbyteArray QByteArray2jbyteArray(const QByteArray & buf)
{
    QAndroidJniEnvironment env;
    jbyteArray array = env->NewByteArray(buf.length());
    env->SetByteArrayRegion(array, 0, buf.length(), reinterpret_cast<jbyte*>((char *)buf.data()));
    return array;
}

QByteArray jbyteArray2QByteArray(jbyteArray buf)
{
    QAndroidJniEnvironment env;
    int len = env->GetArrayLength(buf);
    QByteArray array;
    array.resize(len);
    env->GetByteArrayRegion(buf, 0, len, reinterpret_cast<jbyte*>(array.data()));
    return array;
}

/*
QJNIObjectPrivate QJNIObjectPrivate::fromString(const QString &string)
{
    QJNIEnvironmentPrivate env;
    jstring res = env->NewString(reinterpret_cast<const jchar*>(string.constData()),
                                        string.length());
    QJNIObjectPrivate obj(res);
    env->DeleteLocalRef(res);
    return obj;
}
*/
#endif

bool StorageAccess::updateFile(const QString & fileUri, const QByteArray & fileContent)
{
#if defined(Q_OS_ANDROID)
    QAndroidJniObject jniFileUri = QAndroidJniObject::fromString(fileUri);
    jboolean ok = QAndroidJniObject::callStaticMethod<jboolean>("de/mneuroth/utils/QStorageAccess",
                                              "updateFile",
                                              "(Ljava/lang/String;[B)Z",
                                              jniFileUri.object<jstring>(),
                                              QByteArray2jbyteArray(fileContent));
    return ok;
#endif
    return false;
}

bool StorageAccess::deleteFile(const QString & fileUri)
{
#if defined(Q_OS_ANDROID)
    QAndroidJniObject jniFileUri = QAndroidJniObject::fromString(fileUri);
    jboolean ok = QAndroidJniObject::callStaticMethod<jboolean>("de/mneuroth/utils/QStorageAccess",
                                              "deleteFile",
                                              "(Ljava/lang/String;)Z",
                                              jniFileUri.object<jstring>());
    return ok;
#endif
    return false;
}

bool StorageAccess::readFile(const QString & fileUri, QByteArray & fileContent)
{
#if defined(Q_OS_ANDROID)
    QAndroidJniObject jniFileUri = QAndroidJniObject::fromString(fileUri);

    // see: https://forum.qt.io/topic/42497/solved-android-how-to-get-a-byte-array-from-java/4

    QAndroidJniObject content = QAndroidJniObject::callStaticObjectMethod("de/mneuroth/utils/QStorageAccess",
                                              "readFile",
                                              "(Ljava/lang/String;)[B",
                                              jniFileUri.object<jstring>());

    jbyteArray contentArray = content.object<jbyteArray>();
 /*
    if (!contentArray) {
        qDebug() << Q_FUNC_INFO << "No icon data";

        return false;
    }

    jsize iconSize = env->GetArrayLength(contentArray);

    if (iconSize > 0) {
        jbyte *icon = env->GetByteArrayElements(iconDataArray, false);
        image = QImage(QImage::fromData((uchar*) icon, iconSize,"PNG"));
        env->ReleaseByteArrayElements(iconDataArray, icon, JNI_ABORT);
    }
*/
    QByteArray qContent = jbyteArray2QByteArray(contentArray);
    fileContent = qContent;
//    env->ReleaseByteArrayElements(contentArray, icon, JNI_ABORT);
    return qContent.length()>0;

    //return false;
#else
    return false;
#endif
}

void StorageAccess::createFile(const QString & fileName, const QString & mimeType)
{
#if defined(Q_OS_ANDROID)
    QAndroidJniObject jniFileName = QAndroidJniObject::fromString(fileName);
    QAndroidJniObject jniMimeType = QAndroidJniObject::fromString(mimeType);
    jboolean ok = QAndroidJniObject::callStaticMethod<jboolean>("de/mneuroth/utils/QStorageAccess",
                                              "createFile",
                                              "(Ljava/lang/String;Ljava/lang/String;)Z",
                                              jniFileName.object<jstring>(),
                                              jniMimeType.object<jstring>());
    if(!ok)
    {
        emit openFileError(tr("Error: can not call java method createFile()"));
    }
#endif
}

#if defined(Q_OS_ANDROID)

#ifdef __cplusplus
extern "C" {
#endif

JNIEXPORT void JNICALL
  Java_de_mneuroth_activity_sharex_QShareActivity_fireFileOpenActivityResult(JNIEnv *env,
                                        jobject obj,
                                        jint resultCode,
                                        jstring url,
                                        jstring decodedUrl,
                                        jbyteArray fileContent)
{
    const char *urlStr = env->GetStringUTFChars(url, NULL);
    const char *urlDecodedStr = env->GetStringUTFChars(decodedUrl, NULL);
    jsize contentSize = env->GetArrayLength(fileContent);
    QByteArray * pArray = 0;
    if( contentSize > 0 )
    {
        jboolean isCopy = false;
        jbyte * content = env->GetByteArrayElements(fileContent, &isCopy);
        pArray = new QByteArray((char *)content, contentSize);
        env->ReleaseByteArrayElements(fileContent, content, JNI_ABORT);
    }
    else
    {
        pArray = new QByteArray();
    }
    Q_UNUSED (obj)
    StorageAccess::getInstance()->onFileOpenActivityResult(resultCode, urlStr, urlDecodedStr, *pArray);
    env->ReleaseStringUTFChars(url, urlStr);
    env->ReleaseStringUTFChars(url, urlDecodedStr);
    delete pArray;
    return;
}

JNIEXPORT void JNICALL
  Java_de_mneuroth_activity_sharex_QShareActivity_fireFileCreateActivityResult(JNIEnv *env,
                                        jobject obj,
                                        jint resultCode,
                                        jstring url,
                                        jstring decodedUrl)
{
    const char *urlStr = env->GetStringUTFChars(url, NULL);
    const char *urlDecodedStr = env->GetStringUTFChars(decodedUrl, NULL);
    Q_UNUSED (obj)
    StorageAccess::getInstance()->onFileCreateActivityResult(resultCode, urlStr, urlDecodedStr);
    env->ReleaseStringUTFChars(url, urlStr);
    env->ReleaseStringUTFChars(url, urlDecodedStr);
    return;
}

#ifdef __cplusplus
}
#endif

#endif
