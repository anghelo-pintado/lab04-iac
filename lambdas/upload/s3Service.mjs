import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";

const s3 = new S3Client({});
const bucket = process.env.S3_BUCKET;
const prefix = process.env.UPLOAD_PREFIX || "uploads/";

export const uploadFile = async (buffer, filename, mimetype, uniqueId) => {
  const ext = filename.split(".").pop().toLowerCase();

  const key = `${prefix}${uniqueId}.${ext}`;

  await s3.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: buffer,
      ContentType: mimetype,
    }),
  );

  return key;
};
