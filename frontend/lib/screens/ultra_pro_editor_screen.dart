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
          // Auto-save indicator
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_lastSaved != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  'Sauvegardé ${_formatTimeSince(_lastSaved!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: _showPreviewDialog,
            tooltip: 'Prévisualiser',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _savePublication(),
            tooltip: 'Sauvegarder',
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
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          Icons.image,
                          color: _coverImage != null || _existingCoverImageUrl != null 
                              ? Colors.green 
                              : Colors.grey,
                        ),
                        onPressed: _pickCoverImage,
                        tooltip: 'Image de couverture',
                      ),
                    ],
                  ),
                  if (_coverImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Image sélectionnée: ${_coverImage!.name}',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

          // Toolbar (v9 API)
          quill.QuillToolbar.simple(
            configurations: quill.QuillSimpleToolbarConfigurations(
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
          ),

          // Editor (v9 API)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: quill.QuillEditor(
                scrollController: _scrollController,
                focusNode: _focusNode,
                configurations: quill.QuillEditorConfigurations(
                  controller: _controller,
                  padding: const EdgeInsets.all(16),
                  autoFocus: true,
                  expands: false,
                  scrollable: true,
                ),
              ),
            ),
          ),
          
          // Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                _buildStatItem(Icons.article, 'Mots: $_wordCount'),
                const SizedBox(width: 16),
                _buildStatItem(Icons.text_fields, 'Caractères: $_charCount'),
                const SizedBox(width: 16),
                _buildStatItem(Icons.schedule, 'Lecture: ${(_wordCount / 200).ceil()} min'),
                const Spacer(),
                if (_autoSaveEnabled)
                  const Icon(Icons.cloud_done, color: Colors.green, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
  
  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aperçu',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              // Title
              Text(
                _titleController.text.isEmpty ? 'Sans titre' : _titleController.text,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _isPaid ? Colors.amber[100] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedType + (_isPaid ? ' • Premium' : ''),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isPaid ? Colors.amber[900] : Colors.blue[900],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: quill.QuillEditor(
                    scrollController: ScrollController(),
                    focusNode: FocusNode(canRequestFocus: false),
                    configurations: quill.QuillEditorConfigurations(
                      controller: _controller,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatTimeSince(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  Future<void> _savePublication() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre est requis')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final contentJson = jsonEncode(_controller.document.toDelta().toJson());
      final plainText = _controller.document.toPlainText();
      final excerpt = _excerptController.text.isNotEmpty 
          ? _excerptController.text 
          : (plainText.length > 100 ? plainText.substring(0, 100) + '...' : plainText);

      String? coverImageBase64;
      if (_coverImage != null) {
        final bytes = await _coverImage!.readAsBytes();
        coverImageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } else {
        coverImageBase64 = _existingCoverImageUrl;
      }

      final publicationData = {
        'title': _titleController.text,
        'content': contentJson,
        'excerpt': excerpt,
        'type': _selectedType,
        'isPaid': _isPaid,
        'coverImage': coverImageBase64,
      };

      final authService = Provider.of<AuthService>(context, listen: false);
      final headers = authService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      http.Response response;
      if (widget.publicationId != null) {
        // Update
        response = await http.put(
          Uri.parse('$baseUrl/publications/${widget.publicationId}'),
          headers: headers,
          body: jsonEncode(publicationData),
        );
      } else {
        // Create
        response = await http.post(
          Uri.parse('$baseUrl/publications'),
          headers: headers,
          body: jsonEncode(publicationData),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _lastSaved = DateTime.now();
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publication sauvegardée avec succès')),
        );
        // Si c'est une nouvelle publication, on peut vouloir rester ou sortir
        // Pour l'instant on reste pour permettre de continuer l'édition
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de sauvegarde: $e')),
      );
    }
  }

  void _autoSave() {
    // Auto-save silencieux si le titre est présent
    if (_titleController.text.isNotEmpty && !_isSaving) {
        _savePublication();
    }
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
