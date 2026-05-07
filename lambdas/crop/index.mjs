import {
  S3Client,
  GetObjectCommand,
  PutObjectCommand,
} from "@aws-sdk/client-s3";
import { cropCircular, buildOutputKey } from "./imageProcessor.mjs";

const s3 = new S3Client({});
const bucket = process.env.S3_BUCKET;
const processed_prefix = process.env.PROCESSED_PREFIX ?? "processed/";

export const handler = async (event) => {
  const failures = [];

  for (const record of event.Records) {
    try {
      const body = JSON.parse(record.body);
      const s3Event = body.Records?.[0]?.s3;

      if (!s3Event) throw new Error("Payload S3 inválido");

      const inputKey = decodeURIComponent(
        s3Event.object.key.replace(/\+/g, " "),
      );

      const outputKey = buildOutputKey(inputKey, processed_prefix);

      const { Body } = await s3.send(
        new GetObjectCommand({
          Bucket: bucket,
          Key: inputKey,
        }),
      );
      const inputBuffer = Buffer.from(await streamToBuffer(Body));

      const outputBuffer = await cropCircular(inputBuffer);

      await s3.send(
        new PutObjectCommand({
          Bucket: bucket,
          Key: outputKey,
          Body: outputBuffer,
          ContentType: "image/png",
        }),
      );

      console.log(
        JSON.stringify({
          level: "INFO",
          action: "crop",
          input: inputKey,
          output: outputKey,
        }),
      );
    } catch (err) {
      console.error(
        JSON.stringify({
          level: "ERROR",
          messageId: record.messageId,
          error: err.message,
        }),
      );
      failures.push({ itemIdentifier: record.messageId });
    }
  }

  return { batchItemFailures: failures };
};

async function streamToBuffer(stream) {
  const chunks = [];
  for await (const chunk of stream) chunks.push(chunk);
  return Buffer.concat(chunks);
}
