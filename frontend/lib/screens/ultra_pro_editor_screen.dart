import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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
      
      // Load Quill content
      if (widget.existingData!['content'] != null) {
        try {
          final doc = quill.Document.fromJson(
            jsonDecode(widget.existingData!['content'])
          );
          _controller.document = doc;
        } catch (e) {
          // If not JSON, treat as plain text
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
      headers['Content-Type'] = 'application/json';

      final content = jsonEncode(_controller.document.toDelta().toJson());
      
      final body = jsonEncode({
        'titre': _titleController.text,
        'contenuPrincipal': content,
        'extrait': _excerptController.text,
        'type': _selectedType,
        'estPayant': _isPaid,
        'imageUrl': _existingCoverImageUrl,
      });

      final url = widget.publicationId == null
          ? 'http://192.168.1.8:3000/publications'
          : 'http://192.168.1.8:3000/publications/${widget.publicationId}';

      final response = widget.publicationId == null
          ? await http.post(Uri.parse(url), headers: headers, body: body)
          : await http.put(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _lastSaved = DateTime.now());
        if (showMessage && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Publication sauvegardée'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
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

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);
  }

  void _toggleFocusMode() {
    setState(() => _isFocusMode = !_isFocusMode);
  }

  void _togglePreview() {
    setState(() => _showPreview = !_showPreview);
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return Scaffold(
        body: _buildFullScreenEditor(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.publicationId == null ? 'Nouvelle Publication' : 'Éditer Publication',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Auto-save indicator
          if (_autoSaveEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Row(
                  children: [
                    Icon(
                      _isSaving ? Icons.sync : Icons.check_circle,
                      color: _isSaving ? Colors.orange : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _lastSaved == null
                          ? 'Non sauvegardé'
                          : 'Sauvegardé ${_formatTimeSince(_lastSaved!)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          
          // View mode toggles
          IconButton(
            icon: Icon(_isFocusMode ? Icons.visibility : Icons.visibility_off),
            tooltip: 'Mode Focus',
            onPressed: _toggleFocusMode,
          ),
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.preview),
            tooltip: 'Aperçu',
            onPressed: _togglePreview,
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            tooltip: 'Plein écran',
            onPressed: _toggleFullScreen,
          ),
          
          // Save button
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Sauvegarder',
            onPressed: () => _savePublication(),
          ),
        ],
      ),
      body: _buildEditorBody(),
    );
  }

  Widget _buildEditorBody() {
    if (_isFocusMode) {
      return _buildFocusModeEditor();
    }

    return Row(
      children: [
        // Main editor area
        Expanded(
          flex: _showPreview ? 1 : 2,
          child: _buildMainEditor(),
        ),
        
        // Preview panel
        if (_showPreview)
          Expanded(
            flex: 1,
            child: _buildPreviewPanel(),
          ),
      ],
    );
  }

  Widget _buildMainEditor() {
    return Column(
      children: [
        // Metadata section
        if (!_isFocusMode)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                // Title
                TextField(
                  controller: _titleController,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Titre de la publication...',
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Excerpt
                TextField(
                  controller: _excerptController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Extrait (résumé court)...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Type and options
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: ['Méditation', 'Livret', 'Livre']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Payant'),
                        value: _isPaid,
                        onChanged: (value) => setState(() => _isPaid = value),
                        dense: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _pickCoverImage,
                      icon: const Icon(Icons.image),
                      label: Text(_coverImage != null || _existingCoverImageUrl != null
                          ? 'Changer image'
                          : 'Ajouter image'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        
        // Quill toolbar
        if (!_isFocusMode)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: quill.QuillToolbar.simple(
              controller: _controller,
              configurations: quill.QuillSimpleToolbarConfigurations(
                showAlignmentButtons: true,
                showBackgroundColorButton: true,
                showCenterAlignment: true,
                showClearFormat: true,
                showCodeBlock: true,
                showColorButton: true,
                showDirection: true,
                showDividers: true,
                showFontFamily: true,
                showFontSize: true,
                showHeaderStyle: true,
                showIndent: true,
                showInlineCode: true,
                showJustifyAlignment: true,
                showLeftAlignment: true,
                showLink: true,
                showListBullets: true,
                showListCheck: true,
                showListNumbers: true,
                showQuote: true,
                showRedo: true,
                showRightAlignment: true,
                showSearchButton: true,
                showSmallButton: true,
                showStrikeThrough: true,
                showSubscript: true,
                showSuperscript: true,
                showUnderLineButton: true,
                showUndo: true,
                embedButtons: FlutterQuillEmbeds.toolbarButtons(),
              ),
            ),
          ),
        
        // Editor
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: quill.QuillEditor(
              controller: _controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              configurations: quill.QuillEditorConfigurations(
                padding: const EdgeInsets.all(16),
                placeholder: 'Commencez à écrire votre contenu...',
                autoFocus: false,
                expands: false,
                embedBuilders: FlutterQuillEmbeds.editorBuilders(),
              ),
            ),
          ),
        ),
        
        // Status bar
        if (!_isFocusMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Text('Mots: $_wordCount'),
                const SizedBox(width: 24),
                Text('Caractères: $_charCount'),
                const Spacer(),
                Text('Temps de lecture: ${(_wordCount / 200).ceil()} min'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFocusModeEditor() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 40),
      child: quill.QuillEditor(
        controller: _controller,
        focusNode: _focusNode,
        scrollController: _scrollController,
        configurations: quill.QuillEditorConfigurations(
          padding: const EdgeInsets.all(24),
          placeholder: 'Écrivez en toute tranquillité...',
          embedBuilders: FlutterQuillEmbeds.editorBuilders(),
          customStyles: quill.DefaultStyles(
            paragraph: quill.DefaultTextBlockStyle(
              GoogleFonts.lora(fontSize: 18, height: 1.8),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(8, 8),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.preview, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Aperçu',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _titleController.text.isEmpty
                        ? 'Titre de la publication'
                        : _titleController.text,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Excerpt
                  if (_excerptController.text.isNotEmpty)
                    Text(
                      _excerptController.text,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // Content preview
                  quill.QuillEditor(
                    controller: _controller,
                    configurations: quill.QuillEditorConfigurations(
                      padding: EdgeInsets.zero,
                      embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                    ),
                    focusNode: FocusNode(),
                    scrollController: ScrollController(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenEditor() {
    return Stack(
      children: [
        // Editor
        quill.QuillEditor(
          controller: _controller,
          focusNode: _focusNode,
          scrollController: _scrollController,
          configurations: quill.QuillEditorConfigurations(
            padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 60),
            placeholder: 'Écrivez en plein écran...',
            embedBuilders: FlutterQuillEmbeds.editorBuilders(),
          ),
        ),
        
        // Floating toolbar
        Positioned(
          top: 16,
          right: 16,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.fullscreen_exit),
                    onPressed: _toggleFullScreen,
                    tooltip: 'Quitter plein écran',
                  ),
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () => _savePublication(),
                    tooltip: 'Sauvegarder',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeSince(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
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
