import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class UltraProEditorScreen extends StatefulWidget {
  final String? publicationId;
  final Map<String, dynamic>? existingData;

  const UltraProEditorScreen({
    Key? key,
    this.publicationId,
    this.existingData,
  }) : super(key: key);

  @override
  State<UltraProEditorScreen> createState() => _UltraProEditorScreenState();
}

class _UltraProEditorScreenState extends State<UltraProEditorScreen> {
  final quill.QuillController _controller = quill.QuillController.basic();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _excerptController = TextEditingController();
  
  // Editor state
  bool _isFullScreen = false;
  bool _isFocusMode = false;
  bool _showPreview = false;
  bool _isSaving = false;
  bool _autoSaveEnabled = true;
  DateTime? _lastSaved;
  
  // Document metadata
  String _selectedType = 'Méditation';
  bool _isPaid = false;
  XFile? _coverImage;
  String? _existingCoverImageUrl;
  
  // Statistics
  int _wordCount = 0;
  int _charCount = 0;
  
  // BACKEND URL (Production)
  final String baseUrl = 'https://projet-chretien.onrender.com';

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _setupAutoSave();
    _controller.addListener(_updateStatistics);
  }

  void _loadExistingData() {
    if (widget.existingData != null) {
      _titleController.text = widget.existingData!['title'] ?? '';
      _excerptController.text = widget.existingData!['excerpt'] ?? '';
      _selectedType = widget.existingData!['type'] ?? 'Méditation';
      _isPaid = widget.existingData!['isPaid'] ?? false;
      _existingCoverImageUrl = widget.existingData!['coverImage'];
      
      if (widget.existingData!['content'] != null) {
        try {
          final doc = quill.Document.fromJson(
            jsonDecode(widget.existingData!['content'])
          );
          _controller.document = doc;
        } catch (e) {
          _controller.document = quill.Document()
            ..insert(0, widget.existingData!['content']);
        }
      }
    }
  }

  void _setupAutoSave() {
    if (_autoSaveEnabled) {
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted && _autoSaveEnabled) {
          _autoSave();
          _setupAutoSave();
        }
      });
    }
  }

  void _updateStatistics() {
    final text = _controller.document.toPlainText();
    setState(() {
      _charCount = text.length;
      _wordCount = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    });
  }

  Future<void> _autoSave() async {
    if (!_isSaving && widget.publicationId != null) {
      await _savePublication(showMessage: false);
    }
  }

  Future<void> _savePublication({bool showMessage = true}) async {
    setState(() => _isSaving = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final headers = authService.getAuthHeaders();
      
      final content = jsonEncode(_controller.document.toDelta().toJson());
      
      var request = http.MultipartRequest(
        widget.publicationId == null ? 'POST' : 'PUT',
        Uri.parse('$baseUrl/publications${widget.publicationId == null ? '' : '/${widget.publicationId}'}'),
      );
      
      request.headers.addAll(headers);
      request.fields['titre'] = _titleController.text;
      request.fields['contenuPrincipal'] = content;
      request.fields['extrait'] = _excerptController.text;
      request.fields['type'] = _selectedType;
      request.fields['estPayant'] = _isPaid.toString();
      if (_existingCoverImageUrl != null) {
        request.fields['imageUrl'] = _existingCoverImageUrl!;
      }
      
      if (_coverImage != null) {
        request.files.add(await http.MultipartFile.fromPath('coverImage', _coverImage!.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _lastSaved = DateTime.now());
        if (showMessage && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Publication sauvegardée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickCoverImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _coverImage = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.publicationId == null ? 'Nouvelle Publication' : 'Éditer',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _savePublication(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Metadata Form
          if (!_isFocusMode)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Titre...',
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          items: ['Méditation', 'Livret', 'Livre']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedType = v!),
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(value: _isPaid, onChanged: (v) => setState(() => _isPaid = v)),
                      const Text('Payant'),
                    ],
                  ),
                ],
              ),
            ),

          // Toolbar (v9 API)
          quill.QuillToolbar.basic(
            controller: _controller,
            showAlignmentButtons: true,
            showBoldButton: true,
            showUnderLineButton: true,
            showStrikeThrough: true,
            showColorButton: true,
            showBackgroundColorButton: true,
            showListBullets: true,
            showListNumbers: true,
          ),

          // Editor (v9 API)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: quill.QuillEditor.basic(
                controller: _controller,
                readOnly: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    _excerptController.dispose();
    super.dispose();
  }
}
