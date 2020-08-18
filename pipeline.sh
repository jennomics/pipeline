#!/bin/bash

###############
echo "Retrieving data from S3..."
###############

aws s3 cp s3://awsjenna-staging/test_data.tar.gz s3://awsjenna-data/raw_data/


tar -xvf /mnt/fsx/test_data.tar.gz
rm /mnt/fsx/test_data.tar.gz
echo "###############"
echo "Converting fastq to bam..."
###############

dirname="test_data"
index="/mnt/fsx/reference/hg38/Homo_sapiens_assembly38.fasta.64"
threads=8

cd $dirname
for fwd in `ls *reads_1.fastq`; 

do rev=${fwd/reads_1/reads_2}
	base=${fwd/_reads_1.fastq/}
	bwa mem -t $threads $index $fwd $rev | samtools sort -@16 -o $base.bam -; done

tar -czf ${dirname}_bamfiles.tar.gz *.bam 

echo "###############"
echo "Writing results to S3..."
###############

aws s3 mv ${dirname}_bamfiles.tar.gz s3://awsjenna-data/results/
aws s3 rm s3://awsjenna-staging/test_data.tar.gz

echo "###############"
echo "Terminating instance..."
###############

for f in `curl -s http://169.254.169.254/latest/meta-data/instance-id`; do aws ec2 terminate-instances --region us-west-2 --instance-ids $f; done
