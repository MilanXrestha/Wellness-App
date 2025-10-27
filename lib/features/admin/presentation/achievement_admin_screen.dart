// screens/achievement_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../../core/resources/colors.dart';
import '../../../core/providers/theme_provider.dart';

class AchievementAdminScreen extends StatefulWidget {
  const AchievementAdminScreen({Key? key}) : super(key: key);

  @override
  _AchievementAdminScreenState createState() => _AchievementAdminScreenState();
}

class _AchievementAdminScreenState extends State<AchievementAdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconPathController = TextEditingController();
  final _pointsController = TextEditingController();

  String _selectedGameId = 'breathing_game';
  Map<String, dynamic> _criteria = {};

  // List of all achievements
  List<Map<String, dynamic>> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
    _iconPathController.text = 'assets/icons/achievements/default.png';
    _pointsController.text = '10';
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _iconPathController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _firestore
          .collection('achievements')
          .orderBy('gameId')
          .get();

      setState(() {
        _achievements = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading achievements: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    _idController.clear();
    _titleController.clear();
    _descriptionController.clear();
    _iconPathController.text = 'assets/icons/achievements/default.png';
    _pointsController.text = '10';
    _selectedGameId = 'breathing_game';
    _criteria = {};

    setState(() {});
  }

  Future<void> _saveAchievement() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if ID is valid
    final id = _idController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Achievement ID is required')),
      );
      return;
    }

    // Ensure we have at least one criterion
    if (_criteria.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('At least one achievement criterion is required')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Create achievement data
      final achievementData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'iconPath': _iconPathController.text.trim(),
        'gameId': _selectedGameId,
        'pointsAwarded': int.parse(_pointsController.text.trim()),
        'criteria': _criteria,
      };

      // Save to Firestore
      await _firestore
          .collection('achievements')
          .doc(id)
          .set(achievementData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Achievement saved successfully')),
      );

      // Reload achievements
      _loadAchievements();

      // Reset form
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving achievement: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editAchievement(Map<String, dynamic> achievement) {
    _idController.text = achievement['id'];
    _titleController.text = achievement['title'] ?? '';
    _descriptionController.text = achievement['description'] ?? '';
    _iconPathController.text = achievement['iconPath'] ?? 'assets/icons/achievements/default.png';
    _pointsController.text = (achievement['pointsAwarded'] ?? 10).toString();
    _selectedGameId = achievement['gameId'] ?? 'breathing_game';
    _criteria = Map<String, dynamic>.from(achievement['criteria'] ?? {});

    setState(() {});
  }

  Future<void> _deleteAchievement(String id) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Achievement'),
        content: Text('Are you sure you want to delete this achievement? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await _firestore.collection('achievements').doc(id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Achievement deleted successfully')),
      );

      // Reload achievements
      _loadAchievements();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting achievement: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addCriterion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildCriterionForm(),
    );
  }

  Widget _buildCriterionForm() {
    final criterionTypes = [
      'completedRounds',
      'singleSessionRounds',
      'totalSessions',
      'difficultyCompleted',
      'totalBreathingTime',
    ];

    String criterionType = criterionTypes[0];
    dynamic criterionValue;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: EdgeInsets.all(20.w) + EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Achievement Criterion',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16.h),
              DropdownButtonFormField<String>(
                value: criterionType,
                decoration: InputDecoration(
                  labelText: 'Criterion Type',
                  border: OutlineInputBorder(),
                ),
                items: criterionTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_formatCriterionType(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    criterionType = value!;
                    criterionValue = null;
                  });
                },
              ),
              SizedBox(height: 16.h),
              if (criterionType == 'difficultyCompleted')
                DropdownButtonFormField<String>(
                  value: criterionValue ?? 'beginner',
                  decoration: InputDecoration(
                    labelText: 'Difficulty Level',
                    border: OutlineInputBorder(),
                  ),
                  items: ['beginner', 'intermediate', 'advanced'].map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level.substring(0, 1).toUpperCase() + level.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      criterionValue = value;
                    });
                  },
                )
              else
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Value',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: criterionValue?.toString() ?? '',
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      criterionValue = int.tryParse(value) ?? 0;
                    }
                  },
                ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 16.w),
                  ElevatedButton(
                    onPressed: () {
                      if (criterionValue == null) return;

                      this.setState(() {
                        _criteria[criterionType] = criterionValue;
                      });

                      Navigator.of(context).pop();
                    },
                    child: Text('Add Criterion'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCriterionType(String type) {
    // Convert camelCase to readable format
    final result = type.replaceAllMapped(
      RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)!.toLowerCase()}',
    );

    return result.substring(0, 1).toUpperCase() + result.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('Achievement Admin'),
        leading: IconButton(
          icon: Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCreateForm(isDarkMode),
            SizedBox(height: 32.h),
            Text(
              'All Achievements',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            _buildAchievementsList(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateForm(bool isDarkMode) {
    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _idController.text.isEmpty ? 'Create Achievement' : 'Edit Achievement',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: 'Achievement ID',
                border: OutlineInputBorder(),
                hintText: 'e.g., breathing_master',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Achievement ID is required';
                }
                return null;
              },
              enabled: _idController.text.isEmpty, // Disable when editing
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                hintText: 'e.g., Breathing Master',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                hintText: 'e.g., Complete 10 breathing sessions',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _iconPathController,
              decoration: InputDecoration(
                labelText: 'Icon Path',
                border: OutlineInputBorder(),
                hintText: 'assets/icons/achievements/breathing.png',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Icon path is required';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),
            DropdownButtonFormField<String>(
              value: _selectedGameId,
              decoration: InputDecoration(
                labelText: 'Game',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'breathing_game', child: Text('Mindful Breathing')),
                DropdownMenuItem(value: 'stress_relief_tap', child: Text('Stress-Relief Tap')),
                DropdownMenuItem(value: 'wellness_quiz', child: Text('Wellness Trivia')),
                DropdownMenuItem(value: 'global', child: Text('Global (All Games)')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGameId = value!;
                });
              },
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _pointsController,
              decoration: InputDecoration(
                labelText: 'Points Awarded',
                border: OutlineInputBorder(),
                hintText: '10',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Points are required';
                }
                if (int.tryParse(value) == null) {
                  return 'Must be a valid number';
                }
                return null;
              },
            ),
            SizedBox(height: 24.h),
            Text(
              'Achievement Criteria',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            _criteria.isEmpty
                ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text(
                  'No criteria added yet',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.sp,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
                : Column(
              children: _criteria.entries.map((entry) {
                return ListTile(
                  title: Text(_formatCriterionType(entry.key)),
                  subtitle: Text(entry.value.toString()),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _criteria.remove(entry.key);
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _addCriterion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8.w),
                  Text('Add Criterion'),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _resetForm,
                  child: Text('Reset'),
                ),
                ElevatedButton(
                  onPressed: _saveAchievement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Save Achievement'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsList(bool isDarkMode) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _achievements.length,
      itemBuilder: (context, index) {
        final achievement = _achievements[index];

        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ListTile(
            title: Text(
              achievement['title'] ?? 'Unnamed Achievement',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement['description'] ?? ''),
                SizedBox(height: 4.h),
                Text(
                  'Game: ${_getGameName(achievement['gameId'] ?? '')} | Points: ${achievement['pointsAwarded'] ?? 0}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editAchievement(achievement),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteAchievement(achievement['id']),
                ),
              ],
            ),
            onTap: () => _editAchievement(achievement),
          ),
        );
      },
    );
  }

  String _getGameName(String gameId) {
    switch (gameId) {
      case 'breathing_game':
        return 'Breathing';
      case 'stress_relief_tap':
        return 'Tap';
      case 'wellness_quiz':
        return 'Quiz';
      case 'global':
        return 'Global';
      default:
        return gameId;
    }
  }
}