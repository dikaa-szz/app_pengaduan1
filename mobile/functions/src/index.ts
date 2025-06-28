/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from 'firebase-admin';

admin.initializeApp();

// Function to copy report data to riwayat collection
export const copyReportToRiwayat = onDocumentWritten('reports/{reportId}', async (event) => {
  const snap = event.data;
  const reportData = snap.data();

  if (!reportData) {
    logger.error('No data found in report document.');
    return;
  }

  const userId = reportData.user_id;  // Pastikan bahwa 'user_id' ada di data laporan
  const judul = reportData.title;
  const deskripsi = reportData.description;
  const tanggal = reportData.timestamp;

  try {
    // Menambahkan data ke koleksi 'riwayat'
    await admin.firestore().collection('riwayat').add({
      user_id: userId,
      judul: judul,
      deskripsi: deskripsi,
      tanggal: tanggal,
    });

    logger.info('Laporan berhasil dipindahkan ke riwayat');
  } catch (error) {
    logger.error('Error saat menyalin data ke riwayat: ', error);
  }
});
