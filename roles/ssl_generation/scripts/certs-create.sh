#!/bin/bash

# Cleanup files
rm -f *.crt *.csr *_creds *.jks *.srl *.key *.pem *.der *.p12

PASS=${1:-`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev`}
KEYSTORE_TRUSTORE_PREFIX=${2:-server client}

# Generate CA key
openssl req -new -x509 -keyout snakeoil-ca-1.key -out snakeoil-ca-1.crt -days 365 -subj '/CN=*.*.*/OU=DevOps/O=YourOrganisation/L=Austin/S=Tx/C=US' -passin pass:$PASS -passout pass:$PASS

for i in $KEYSTORE_TRUSTORE_PREFIX; do
	echo "------------------------------- $i -------------------------------"

	echo "Create host keystore"
	keytool -genkey -noprompt \
		-alias $i \
		-dname "CN=$i,OU=DevOps,O=YourOrganisation,L=Austin,S=Tx,C=US" \
		-ext san=dns:$i \
		-keystore $i.keystore.jks \
		-keyalg RSA \
		-storepass $PASS \
		-keypass $PASS

	# Create the certificate signing request (CSR)
	echo "Create the certificate signing request (CSR)"
	keytool -noprompt -keystore $i.keystore.jks -alias $i -certreq -file $i.csr -storepass $PASS -keypass $PASS

	# Sign the host certificate with the certificate authority (CA)
	echo "Sign the host certificate with the certificate authority (CA)"
	openssl x509 -req -CA snakeoil-ca-1.crt -CAkey snakeoil-ca-1.key -in $i.csr -out $i-ca1-signed.crt -days 9999 -CAcreateserial -passin pass:$PASS

	# Sign and import the CA cert into the keystore
	echo "Sign and import the CA cert into the keystore"
	keytool -noprompt -keystore $i.keystore.jks -alias CARoot -import -file snakeoil-ca-1.crt -storepass $PASS -keypass $PASS

	# Sign and import the host certificate into the keystore
	echo "Sign and import the host certificate into the keystore"
	keytool -noprompt -keystore $i.keystore.jks -alias $i -import -file $i-ca1-signed.crt -storepass $PASS -keypass $PASS

	# Create truststore and import the CA cert
	echo "Create truststore and import the CA cert"
	keytool -noprompt -keystore $i.truststore.jks -alias CARoot -import -file snakeoil-ca-1.crt -storepass $PASS -keypass $PASS

	# Save creds
	echo "$PASS" > ${i}_sslkey_creds
	echo "$PASS" > ${i}_keystore_creds
	echo "$PASS" > ${i}_truststore_creds
done
