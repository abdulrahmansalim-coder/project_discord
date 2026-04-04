<?php

namespace App\Controllers;

class UploadController extends BaseController
{
    // POST /api/v1/upload/image
    public function image()
    {
        $file = $this->request->getFile('image');

        if (!$file || !$file->isValid()) {
            return $this->badRequest('No image file provided');
        }

        $allowed = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
        if (!in_array($file->getMimeType(), $allowed)) {
            return $this->badRequest('Invalid file type. Only JPG, PNG, GIF, WEBP allowed.');
        }

        if ($file->getSize() > 5 * 1024 * 1024) {
            return $this->badRequest('File too large. Maximum size is 5MB.');
        }

        $uploadPath = FCPATH . 'uploads/images/';
        if (!is_dir($uploadPath)) {
            mkdir($uploadPath, 0755, true);
        }

        $newName = $file->getRandomName();
        $file->move($uploadPath, $newName);

        $baseUrl = rtrim(base_url(), '/');
        $url     = $baseUrl . '/uploads/images/' . $newName;

        return $this->created(['url' => $url], 'Image uploaded successfully');
    }

    // Keep serve() for backwards compatibility with old messages
    public function serve($filename = null)
    {
        if (!$filename) return $this->notFound('No filename provided');
        $filename = basename($filename);
        $filePath = FCPATH . 'uploads/images/' . $filename;
        if (!file_exists($filePath)) {
            // fallback to writable
            $filePath = WRITEPATH . 'uploads/' . $filename;
            if (!file_exists($filePath)) return $this->notFound('Image not found');
        }
        $mime = mime_content_type($filePath) ?: 'image/jpeg';
        return $this->response
            ->setHeader('Content-Type', $mime)
            ->setHeader('Cache-Control', 'public, max-age=86400')
            ->setBody(file_get_contents($filePath));
    }
}
