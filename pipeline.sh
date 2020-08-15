#!/bin/bash

###############
echo "Retrieving data from S3..."
###############

aws s3 cp s3://awsjenna-data/test_data.zip .


unzip test_data.zip

echo "###############"
echo "Converting fastq to bam..."
###############

dirname="test_data"
index="/mnt/efs/reference/hg38/Homo_sapiens_assembly38.fasta"
threads=16

cd $dirname
for fwd in `ls *reads_1.fastq`; 

do rev=${fwd/reads_1/reads_2}
	base=${fwd/_reads_1.fastq/}
	bwa mem -t $threads $index $fwd $rev | samtools sort -@16 -o $base.bam -; done

tar -czf ${dirname}_bamfiles.tar.gz *.bam 

echo "###############"
echo "Writing results to S3..."
###############

aws s3 mv ${dirname}_bamfiles.tar.gz s3://awsjenna-results/

echo "###############"
echo "Terminating instance..."
###############

#for f in `curl -s http://169.254.169.254/latest/meta-data/instance-id`; do aws ec2 terminate-instances --region us-west-2 --instance-ids $f; done
