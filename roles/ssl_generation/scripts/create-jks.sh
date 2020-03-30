#!/bin/bash 

# Cleanup files
rm -f *.crt *.csr *_creds *.jks *.srl *.key *.pem *.der *.p12

PASS=${1:-`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev`}
KEYSTORE_TRUSTORE_PREFIX=${2:-host}
BROKER_CERT=${3:-cert.pem}
BROKER_KEY=${4:-cert.key}
ROOT_CERT=${5:-root.pem}
INT_CERT=${6:-intermediate.pem}
OPEN_SSL_PASS_FORMAT="pass:$PASS"

for i in $KEYSTORE_TRUSTORE_PREFIX
do
        echo "------------------------------- $i -------------------------------"

        openssl pkcs12 -export -in $BROKER_CERT -inkey $BROKER_KEY > host.p12 -passout $OPEN_SSL_PASS_FORMAT -passin $OPEN_SSL_PASS_FORMAT

        keytool -importkeystore -deststorepass $PASS  -destkeystore $i.keystore.jks -srcstorepass $PASS -srckeystore host.p12 -srcstoretype PKCS12

        keytool -noprompt -keystore $i.keystore.jks -alias CARoot -import -file $ROOT_CERT  -storepass $PASS -keypass $PASS

        keytool -noprompt -keystore $i.keystore.jks -alias CAInt -import -file $INT_CERT  -storepass $PASS -keypass $PASS

        keytool -noprompt -keystore $i.keystore.jks -alias client -import -file $BROKER_CERT -storepass $PASS -keypass $PASS


        keytool -noprompt -keystore $i.truststore.jks -alias CARoot -import -file $ROOT_CERT  -storepass $PASS -keypass $PASS

        keytool -noprompt -keystore $i.truststore.jks -alias CAInt -import -file $INT_CERT  -storepass $PASS -keypass $PASS

        keytool -noprompt -keystore $i.truststore.jks -alias client -import -file $BROKER_CERT -storepass $PASS -keypass $PASS

        # Save creds
        echo "$PASS" > ${i}_sslkey_creds
        echo "$PASS" > ${i}_keystore_creds
        echo "$PASS" > ${i}_truststore_creds

done

