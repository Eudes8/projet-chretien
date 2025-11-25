import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/publication.dart';
import '../services/publication_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class PublicationEditorScreen extends StatefulWidget {
  final Publication? publication;

  const PublicationEditorScreen({super.key, this.publication});

  @override
  State<PublicationEditorScreen> createState() => _PublicationEditorScreenState();
}

class _PublicationEditorScreenState extends State<PublicationEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late QuillController _quillController;
  late TextEditingController _excerptController;
  
  String _type = 'Meditation';
  bool _estPayant = false;
  bool _isLoading = false;
  bool _isFullScreen = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.publication?.titre ?? '');
    _excerptController = TextEditingController(text: widget.publication?.extrait ?? '');
    _type = widget.publication?.type ?? 'Meditation';
    _estPayant = widget.publication?.estPayant ?? false;

    _initQuill();
  }

  void _initQuill() {
    try {
      if (widget.publication?.contenuPrincipal != null && widget.publication!.contenuPrincipal!.isNotEmpty) {
        // Try to parse as JSON Delta
        var json = jsonDecode(widget.publication!.contenuPrincipal!);
        _quillController = QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } else {
        _quillController = QuillController.basic();
      }
    } catch (e) {
      // Fallback to plain text if not JSON
      _quillController = QuillController(
        document: Document()..insert(0, widget.publication?.contenuPrincipal ?? ''),
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _excerptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Convert Quill content to JSON Delta string
    final contentJson = jsonEncode(_quillController.document.toDelta().toJson());

    final data = {
      'titre': _titleController.text,
      'contenuPrincipal': contentJson,
      'extrait': _excerptController.text,
      'type': _type,
      'estPayant': _estPayant,
      // imageUrl is handled by backend if file is uploaded, or kept if not changed
      if (widget.publication != null && _selectedImage == null) 'imageUrl': widget.publication!.imageUrl,
    };

    try {
      if (widget.publication == null) {
        await PublicationService().createPublication(data, authService.getAuthHeaders(), imageFile: _selectedImage);
      } else {
        await PublicationService().updatePublication(widget.publication!.id, data, authService.getAuthHeaders(), imageFile: _selectedImage);
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return _buildFullScreenEditor();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.publication == null ? 'Nouvelle Publication' : 'Modifier Publication',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: () => setState(() => _isFullScreen = true),
            tooltip: 'Mode plein écran',
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Informations Générales'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: _buildInputDecoration('Titre', Icons.title),
                      validator: (value) => value!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: _buildInputDecoration('Type de contenu', Icons.category),
                      items: ['Meditation', 'Livret', 'Livre']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) => setState(() => _type = val!),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle('Contenu (Éditeur Professionnel)'),
                    const SizedBox(height: 16),
                    
                    // Enhanced Quill Editor
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Enhanced Toolbar
                          _buildEnhancedToolbar(),
                          const Divider(height: 1),
                          Container(
                            height: 500,
                            padding: const EdgeInsets.all(16),
                            child: QuillEditor.basic(
                              controller: _quillController,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    TextFormField(
                      controller: _excerptController,
                      decoration: _buildInputDecoration('Extrait (Optionnel)', Icons.short_text).copyWith(
                        alignLabelWithHint: true,
                        hintText: 'Résumé court pour la liste des publications...',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle('Média & Options'),
                    const SizedBox(height: 16),
                    
                    // Image Picker Widget
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          image: _selectedImageBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_selectedImageBytes!),
                                  fit: BoxFit.cover,
                                )
                              : (widget.publication?.imageUrl != null && widget.publication!.imageUrl!.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(widget.publication!.imageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: (_selectedImageBytes == null && (widget.publication?.imageUrl == null || widget.publication!.imageUrl!.isEmpty))
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text('Ajouter une couverture', style: TextStyle(color: Colors.grey[600])),
                                ],
                              )
                            : null,
                      ),
                    ),
                    if (_selectedImageBytes != null || (widget.publication?.imageUrl != null && widget.publication!.imageUrl!.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.edit),
                          label: const Text('Changer l\'image'),
                        ),
                      ),

                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SwitchListTile(
                        title: const Text('Contenu Payant (Premium)'),
                        subtitle: const Text('Nécessite un abonnement pour accéder'),
                        value: _estPayant,
                        onChanged: (val) => setState(() => _estPayant = val),
                        activeColor: AppTheme.primaryGold,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'ENREGISTRER',
                          style: GoogleFonts.lato(fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFullScreenEditor() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Compact Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.fullscreen_exit),
                    onPressed: () => setState(() => _isFullScreen = false),
                    tooltip: 'Quitter plein écran',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _titleController.text.isEmpty ? 'Document sans titre' : _titleController.text,
                      style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer'),
                  ),
                ],
              ),
            ),
            // Toolbar
            _buildEnhancedToolbar(),
            const Divider(height: 1),
            // Editor
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(40),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QuillEditor.basic(
                  controller: _quillController,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: _isFullScreen ? null : const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          // Formatting
          _buildToolbarSection([
            _buildToolbarButton(Icons.format_bold, 'Gras (Ctrl+B)', () {
              _quillController.formatSelection(Attribute.bold);
            }),
            _buildToolbarButton(Icons.format_italic, 'Italique (Ctrl+I)', () {
              _quillController.formatSelection(Attribute.italic);
            }),
            _buildToolbarButton(Icons.format_underline, 'Souligné (Ctrl+U)', () {
              _quillController.formatSelection(Attribute.underline);
            }),
            _buildToolbarButton(Icons.strikethrough_s, 'Barré', () {
              _quillController.formatSelection(Attribute.strikeThrough);
            }),
          ]),
          
          _buildDivider(),
          
          // Alignment
          _buildToolbarSection([
            _buildToolbarButton(Icons.format_align_left, 'Aligner à gauche', () {
              _quillController.formatSelection(Attribute.leftAlignment);
            }),
            _buildToolbarButton(Icons.format_align_center, 'Centrer', () {
              _quillController.formatSelection(Attribute.centerAlignment);
            }),
            _buildToolbarButton(Icons.format_align_right, 'Aligner à droite', () {
              _quillController.formatSelection(Attribute.rightAlignment);
            }),
            _buildToolbarButton(Icons.format_align_justify, 'Justifier', () {
              _quillController.formatSelection(Attribute.justifyAlignment);
            }),
          ]),
          
          _buildDivider(),
          
          // Lists
          _buildToolbarSection([
            _buildToolbarButton(Icons.format_list_bulleted, 'Liste à puces', () {
              _quillController.formatSelection(Attribute.ul);
            }),
            _buildToolbarButton(Icons.format_list_numbered, 'Liste numérotée', () {
              _quillController.formatSelection(Attribute.ol);
            }),
            _buildToolbarButton(Icons.format_indent_increase, 'Augmenter retrait', () {
              _quillController.formatSelection(Attribute.indentL1);
            }),
            _buildToolbarButton(Icons.format_indent_decrease, 'Diminuer retrait', () {
              _quillController.formatSelection(Attribute.clone(Attribute.indentL1, null));
            }),
          ]),
          
          _buildDivider(),
          
          // Headers
          _buildToolbarSection([
            _buildToolbarButton(Icons.title, 'Titre 1', () {
              _quillController.formatSelection(Attribute.h1);
            }, size: 24),
            _buildToolbarButton(Icons.title, 'Titre 2', () {
              _quillController.formatSelection(Attribute.h2);
            }, size: 20),
            _buildToolbarButton(Icons.title, 'Titre 3', () {
              _quillController.formatSelection(Attribute.h3);
            }, size: 18),
          ]),
          
          _buildDivider(),
          
          // Blocks
          _buildToolbarSection([
            _buildToolbarButton(Icons.format_quote, 'Citation', () {
              _quillController.formatSelection(Attribute.blockQuote);
            }),
            _buildToolbarButton(Icons.code, 'Bloc de code', () {
              _quillController.formatSelection(Attribute.codeBlock);
            }),
            _buildToolbarButton(Icons.horizontal_rule, 'Ligne horizontale', () {
              _quillController.document.insert(_quillController.selection.baseOffset, '\n---\n');
            }),
          ]),
          
          _buildDivider(),
          
          // Clear & Undo/Redo
          _buildToolbarSection([
            _buildToolbarButton(Icons.format_clear, 'Effacer format', () {
              _quillController.formatSelection(Attribute.clone(Attribute.bold, null));
              _quillController.formatSelection(Attribute.clone(Attribute.italic, null));
              _quillController.formatSelection(Attribute.clone(Attribute.underline, null));
            }),
            _buildToolbarButton(Icons.undo, 'Annuler (Ctrl+Z)', () {
              _quillController.undo();
            }),
            _buildToolbarButton(Icons.redo, 'Refaire (Ctrl+Y)', () {
              _quillController.redo();
            }),
          ]),
        ],
      ),
    );
  }

  Widget _buildToolbarSection(List<Widget> buttons) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: buttons,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.grey[300],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryBlue,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String tooltip, VoidCallback onPressed, {double size = 22}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(icon, size: size, color: AppTheme.primaryBlue),
        ),
      ),
    );
  }
}
