import 'package:flutter/material.dart';
import '../config.dart';
import '../widgets/common.dart';
import 'sync_page.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback onSaved;
  final Future<void> Function()? onDataRestored;

  const ProfilePage({super.key, required this.onSaved, this.onDataRestored});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _heightCtl;
  late TextEditingController _startWeightCtl;
  late TextEditingController _targetWeightCtl;
  late TextEditingController _startDateCtl;
  late TextEditingController _targetDateCtl;
  late TextEditingController _calorieCtl;
  late TextEditingController _bmrCtl;
  late TextEditingController _occupationCtl;

  @override
  void initState() {
    super.initState();
    _heightCtl = TextEditingController(
      text: AppConfig.height.toStringAsFixed(0),
    );
    _startWeightCtl = TextEditingController(
      text: (AppConfig.startWeight * 2).toStringAsFixed(1),
    );
    _targetWeightCtl = TextEditingController(
      text: (AppConfig.targetWeight * 2).toStringAsFixed(1),
    );
    _startDateCtl = TextEditingController(text: AppConfig.startDate);
    _targetDateCtl = TextEditingController(text: AppConfig.targetDate);
    _calorieCtl = TextEditingController(
      text: AppConfig.dailyCalorieTarget.toString(),
    );
    _bmrCtl = TextEditingController(text: AppConfig.bmr.toString());
    _occupationCtl = TextEditingController(text: AppConfig.occupation);
  }

  @override
  void dispose() {
    _heightCtl.dispose();
    _startWeightCtl.dispose();
    _targetWeightCtl.dispose();
    _startDateCtl.dispose();
    _targetDateCtl.dispose();
    _calorieCtl.dispose();
    _bmrCtl.dispose();
    _occupationCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctl) async {
    final parts = ctl.text.split('-');
    DateTime initial;
    try {
      initial = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      initial = DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: C.green,
              onSurface: C.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ctl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    final height = double.tryParse(_heightCtl.text);
    final startJin = double.tryParse(_startWeightCtl.text);
    final targetJin = double.tryParse(_targetWeightCtl.text);
    final calorie = int.tryParse(_calorieCtl.text);
    final bmr = int.tryParse(_bmrCtl.text);

    if (height == null || height < 100 || height > 250) {
      _showError('身高请输入 100-250 cm');
      return;
    }
    if (startJin == null || startJin < 60 || startJin > 400) {
      _showError('起始体重请输入 60-400 斤');
      return;
    }
    if (targetJin == null || targetJin < 60 || targetJin > 400) {
      _showError('目标体重请输入 60-400 斤');
      return;
    }
    if (calorie == null || calorie < 800 || calorie > 4000) {
      _showError('每日热量目标请输入 800-4000 kcal');
      return;
    }
    if (bmr == null || bmr < 800 || bmr > 4000) {
      _showError('基础代谢率请输入 800-4000 kcal');
      return;
    }

    AppConfig.height = height;
    AppConfig.startWeight = startJin / 2.0;
    AppConfig.targetWeight = targetJin / 2.0;
    AppConfig.startDate = _startDateCtl.text;
    AppConfig.targetDate = _targetDateCtl.text;
    AppConfig.dailyCalorieTarget = calorie;
    AppConfig.bmr = bmr;
    AppConfig.occupation = _occupationCtl.text.trim();

    await AppConfig.save();
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: C.rose));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: C.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '个人资料',
          style: TextStyle(
            color: C.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _section('身体数据', [
            _numField('身高', _heightCtl, 'cm'),
            _numField('起始体重', _startWeightCtl, '斤'),
            _numField('目标体重', _targetWeightCtl, '斤'),
          ]),
          const SizedBox(height: 8),
          _section('目标时间', [
            _dateField('开始日期', _startDateCtl),
            _dateField('目标日期', _targetDateCtl),
          ]),
          const SizedBox(height: 8),
          _section('热量设置', [
            _numField('每日热量目标', _calorieCtl, 'kcal'),
            _numField('基础代谢率 (BMR)', _bmrCtl, 'kcal'),
          ]),
          const SizedBox(height: 8),
          _section('个人信息', [_textField('职业/生活方式', _occupationCtl, '如：久坐程序员')]),
          const SizedBox(height: 8),
          _section('数据同步', [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SyncPage(onSynced: widget.onDataRestored),
                  ),
                );
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: C.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: C.border),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_sync_rounded, color: C.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '打开云同步',
                      style: TextStyle(
                        color: C.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          GradientButton(text: '保存', icon: Icons.check_rounded, onTap: _save),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: C.green,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _numField(String label, TextEditingController ctl, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: C.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.border),
              ),
              child: TextField(
                controller: ctl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: C.textPrimary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  suffixText: unit,
                  suffixStyle: TextStyle(
                    fontSize: 13,
                    color: C.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField(String label, TextEditingController ctl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: C.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.border),
              ),
              child: TextField(
                controller: ctl,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: C.textPrimary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  hintText: hint,
                  hintStyle: TextStyle(fontSize: 14, color: C.textDim),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, TextEditingController ctl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: C.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _pickDate(ctl),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: C.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: C.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                child: Text(
                  ctl.text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: C.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
