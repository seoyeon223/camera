import 'package:flutter/material.dart';

class BusinessRegisterScreen extends StatefulWidget {
  const BusinessRegisterScreen({super.key});

  @override
  State<BusinessRegisterScreen> createState() =>
      _BusinessRegisterScreenState();
}

class _BusinessRegisterScreenState extends State<BusinessRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailLocationController =
      TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  String _storeType = '카페';
  bool _hasCctv = false;
  bool _hasRecentInspection = false;
  bool _hasSeparatedStalls = true;
  bool _hasEmergencyBell = false;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('신청 완료'),
          content: const Text(
            '업소 등록 신청이 접수되었습니다.\n관리자 검토 후 지도에 반영됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _detailLocationController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('업소 등록 신청'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '우리 업소를 안전 지도에 등록해보세요',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '기본 정보와 안전 관련 항목을 입력하면 관리자가 검토 후 지도에 반영합니다.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _SectionTitle(title: '기본 정보'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _storeNameController,
                decoration: const InputDecoration(
                  labelText: '업소명',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '업소명을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _storeType,
                decoration: const InputDecoration(
                  labelText: '업소 유형',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: '카페', child: Text('카페')),
                  DropdownMenuItem(value: '음식점', child: Text('음식점')),
                  DropdownMenuItem(value: '상가', child: Text('상가')),
                  DropdownMenuItem(value: '학원', child: Text('학원')),
                  DropdownMenuItem(value: '기타', child: Text('기타')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _storeType = value;
                  });
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: '담당자명',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '담당자명을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '연락처',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '연락처를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '주소',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '주소를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _detailLocationController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '화장실 위치 설명',
                  hintText: '예: 2층 계단 옆, 매장 안쪽 복도 끝',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              _SectionTitle(title: '안전 점검 항목'),
              const SizedBox(height: 8),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('외부 CCTV가 설치되어 있어요'),
                value: _hasCctv,
                onChanged: (value) {
                  setState(() {
                    _hasCctv = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('최근 점검 이력이 있어요'),
                value: _hasRecentInspection,
                onChanged: (value) {
                  setState(() {
                    _hasRecentInspection = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('칸막이 구조가 비교적 안전해요'),
                value: _hasSeparatedStalls,
                onChanged: (value) {
                  setState(() {
                    _hasSeparatedStalls = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('비상 호출 장치가 있어요'),
                value: _hasEmergencyBell,
                onChanged: (value) {
                  setState(() {
                    _hasEmergencyBell = value ?? false;
                  });
                },
              ),

              const SizedBox(height: 20),
              _SectionTitle(title: '추가 메모'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _memoController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '추가 설명',
                  hintText: '점검 주기, 특이사항, 관리자에게 전달할 내용을 적어주세요.',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('등록 신청 보내기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}