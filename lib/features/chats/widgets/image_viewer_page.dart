import 'dart:io';

import 'package:flutter/material.dart';

class ImageViewerPage extends StatelessWidget {
  const ImageViewerPage({
    super.key,
    required this.imagePath,
    this.isNetworkImage = false,
  });

  final String imagePath;
  final bool isNetworkImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Descarga no implementada')),
              );
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: isNetworkImage
              ? Image.network(
                  imagePath,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.error_outline, color: Colors.white, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'No se pudo cargar la imagen',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.error_outline, color: Colors.white, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'No se pudo cargar la imagen',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
