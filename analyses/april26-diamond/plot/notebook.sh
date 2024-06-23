ec2_public_ip=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
echo "ip: $ec2_public_ip"
bash -c "jupyter notebook --port 40157 --ip  0.0.0.0"
