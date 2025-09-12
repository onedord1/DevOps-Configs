# backup gitlab
 docker exec -t gitlab-main-server gitlab-backup create


# install mc
curl https://dl.min.io/client/mc/release/linux-amd64/mc \
  --create-dirs \
  -o $HOME/minio-binaries/mc

chmod +x $HOME/minio-binaries/mc
export PATH=$PATH:$HOME/minio-binaries/



#  run minio
docker run \
   -p 9000:9000 \
   -p 9001:9001 \
   --name minio \
   -v ~/minio/data:/data \
   -e "MINIO_ROOT_USER=ROOTNAME" \
   -e "MINIO_ROOT_PASSWORD=CHANGEME123" \
   quay.io/minio/minio server /data --console-address ":9001"



# set hostname
/ets/hosts
172.17.19.252 bucket.cloudaes.com

# get the crt of the website
 openssl s_client -showcerts -connect bucket.cloudaes.com:443 </dev/null 2>/dev/null | openssl x509 -outform PEM > bucket.cloudaes.com.crt

# copy to minio known crts
 cp bucket.cloudaes.com.crt ~/.mc/certs/CAs/


 # set creds
  mc alias set test123 https://bucket.cloudaes.com accesskey secretkey

 # list buckets
   mc ls  test123

  
 #  copy data
   mc cp -r backup/ alias/bucketname


