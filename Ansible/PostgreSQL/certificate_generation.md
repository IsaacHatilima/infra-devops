# Generate Certificates

## Install openssl

sudo apt install openssl

## Cert folder

mkdir certs
cd certs

## Generate cert authority

openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -subj "/CN=etcd-ca" -days 7300 -out ca.crt

## node1

### Generate a private key
openssl genrsa -out etcd-postgres1.key 2048

### Create temp file for config
cat > temp.cnf <<EOF
[ req ]
distinguished_name = req_distinguished_name
req_extensions = v3_req
[ req_distinguished_name ]
[ v3_req ]
subjectAltName = @alt_names
[ alt_names ]
IP.1 = 192.168.10.2
IP.2 = 127.0.0.1
EOF

### Create a csr
openssl req -new -key etcd-postgres1.key -out etcd-postgres1.csr \
  -subj "/C=DE/ST=Bavaria/L=Regensburg/O=Mubuyu/OU=Main/CN=etcd-postgres1" \
  -config temp.cnf

### Sign the cert
openssl x509 -req -in etcd-postgres1.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out etcd-postgres1.crt -days 7300 -sha256 -extensions v3_req -extfile temp.cnf

### Verify the cert and be sure you see Subject Name Alternative

openssl x509 -in etcd-postgres1.crt -text -noout | grep -A1 "Subject Alternative Name"

### Remove temp file

rm temp.cnf

## node2

### Generate a private key
openssl genrsa -out etcd-postgres2.key 2048

### Create temp file for config
cat > temp.cnf <<EOF
[ req ]
distinguished_name = req_distinguished_name
req_extensions = v3_req
[ req_distinguished_name ]
[ v3_req ]
subjectAltName = @alt_names
[ alt_names ]
IP.1 = 192.168.10.3
IP.2 = 127.0.0.1
EOF

### Create a csr
openssl req -new -key etcd-postgres2.key -out etcd-postgres2.csr \
  -subj "/C=DE/ST=Bavaria/L=Regensburg/O=Mubuyu/OU=Main/CN=etcd-postgres2" \
  -config temp.cnf

### Sign the cert
openssl x509 -req -in etcd-postgres2.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out etcd-postgres2.crt -days 7300 -sha256 -extensions v3_req -extfile temp.cnf

### Verify the cert and be sure you see Subject Name Alternative
openssl x509 -in etcd-postgres2.crt -text -noout | grep -A1 "Subject Alternative Name"

### Remove temp file
rm temp.cnf

## Node3

### Generate a private key
openssl genrsa -out etcd-postgres3.key 2048

### Create temp file for config
cat > temp.cnf <<EOF
[ req ]
distinguished_name = req_distinguished_name
req_extensions = v3_req
[ req_distinguished_name ]
[ v3_req ]
subjectAltName = @alt_names
[ alt_names ]
IP.1 = 192.168.10.4
IP.2 = 127.0.0.1
EOF

### Create a csr
openssl req -new -key etcd-postgres3.key -out etcd-postgres3.csr \
  -subj "/C=DE/ST=Bavaria/L=Regensburg/O=Mubuyu/OU=Main/CN=etcd-postgres3" \
  -config temp.cnf

### Sign the cert

openssl x509 -req -in etcd-postgres3.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out etcd-postgres3.crt -days 7300 -sha256 -extensions v3_req -extfile temp.cnf

### Verify the cert and be sure you see Subject Name Alternative
openssl x509 -in etcd-postgres3.crt -text -noout | grep -A1 "Subject Alternative Name"

### Remove temp file
rm temp.cnf

## Copy files

scp -P 1992 ca.crt etcd-postgres1.crt etcd-postgres1.key isaac@10.100.100.3:/tmp/
scp -P 1992 ca.crt etcd-postgres2.crt etcd-postgres2.key isaac@10.100.100.4:/tmp/
scp -P 1992 ca.crt etcd-postgres3.crt etcd-postgres3.key isaac@10.100.100.5:/tmp/

## Server Certificate
openssl genrsa -out server.key 2048 
openssl req -new -key server.key -out server.req # csr
openssl req -x509 -key server.key -in server.req -out server.crt -days 7300 # generate cert, valid for 20 years
chmod 600 server.key

## Copy Files

scp -P 1992 server.crt server.key server.req isaac@10.100.100.3:/tmp
scp -P 1992 server.crt server.key server.req isaac@10.100.100.4:/tmp
scp -P 1992 server.crt server.key server.req isaac@10.100.100.5:/tmp
