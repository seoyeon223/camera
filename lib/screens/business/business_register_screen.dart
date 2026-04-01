import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusinessRegisterScreen extends StatefulWidget {
  const BusinessRegisterScreen({super.key});

  @override
  State<BusinessRegisterScreen> createState() => _BusinessRegisterScreenState();
}

class _BusinessRegisterScreenState extends State<BusinessRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // 텍스트 컨트롤러
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailLocationController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  // 상태 변수
  String _storeType = '카페';
  bool _hasCctv = false;
  bool _hasRecentInspection = false;
  bool _hasSeparatedStalls = true;
  bool _hasEmergencyBell = false;

  // 📍 위치 인증 관련 변수
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isLocationVerified = false;

  // 📸 사진 업로드 관련 변수 (여러 장 등록 가능)
  final List<File> _photos = [];
  final ImagePicker _picker = ImagePicker();

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

  // 📍 현장 위치 인증 함수
  Future<void> _verifyCurrentLocation() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('주소를 먼저 입력해 주세요!')));
      return;
    }

    setState(() { _isLoadingLocation = true; });
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _isLocationVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('현장 위치가 성공적으로 인증되었습니다.')));
    } catch (e) {
      debugPrint('위치 수집 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('위치 인증에 실패했습니다. GPS 권한을 확인해주세요.')));
    } finally {
      setState(() { _isLoadingLocation = false; });
    }
  }

  // 📸 사진 추가 함수 (카메라 또는 갤러리 선택)
  Future<void> _addPhoto() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영하기'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) setState(() => _photos.add(File(pickedFile.path)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택하기'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) setState(() => _photos.add(File(pickedFile.path)));
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🗑️ 사진 삭제 함수
  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  // 🚀 최종 제출 함수
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLocationVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('현장 위치 인증을 진행해 주세요.')));
      return;
    }

    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('안전 시설(CCTV, 칸막이 등) 사진을 최소 1장 이상 첨부해 주세요.')));
      return;
    }

    // 💡 여기서 현재 폰에 접속 중인 익명 유저의 UID를 가져옵니다!
    final String userUid = FirebaseAuth.instance.currentUser?.uid ?? '알_수_없음';

    // 등록 데이터 묶기
    final businessData = {
      'uploader_uid': userUid, // 👈 핵심! 등록 요청자 UID를 포함시킵니다.
      'store_name': _storeNameController.text,
      'store_type': _storeType,
      'owner_name': _ownerNameController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
      'detail_location': _detailLocationController.text,
      'lat': _currentPosition?.latitude,
      'lng': _currentPosition?.longitude,
      'has_cctv': _hasCctv,
      'has_recent_inspection': _hasRecentInspection,
      'has_separated_stalls': _hasSeparatedStalls,
      'has_emergency_bell': _hasEmergencyBell,
      'memo': _memoController.text,
      // 사진(File)은 나중에 Firebase Storage에 업로드하고 URL을 받아와서 넣어야 합니다.
    };

    debugPrint('서버로 전송될 업소 등록 데이터: $businessData');
    await FirebaseFirestore.instance.collection('businesses').add({
      ...businessData,
      'createdAt': FieldValue.serverTimestamp(), // 현재 시간 기록
      'status': '심사중', // 기본 상태
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('신청 완료'),
          content: const Text('업소 등록 신청이 접수되었습니다.\n관리자가 사진과 위치를 검토한 후 지도에 반영합니다.'),
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('업소 등록 신청')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 안내 문구
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('우리 업소를 안전 지도에 등록해보세요', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('위치 인증과 안전 시설 사진을 첨부해주시면, 관리자 검토 후 신뢰할 수 있는 안심 화장실로 지도에 등록됩니다.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 1. 기본 정보
              const _SectionTitle(title: '기본 정보 입력'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _storeNameController,
                decoration: const InputDecoration(labelText: '업소명', border: OutlineInputBorder()),
                validator: (value) => value!.trim().isEmpty ? '업소명을 입력해주세요.' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _storeType,
                decoration: const InputDecoration(labelText: '업소 유형', border: OutlineInputBorder()),
                items: ['카페', '음식점', '상가', '학원', '기타'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => setState(() => _storeType = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(labelText: '담당자명', border: OutlineInputBorder()),
                validator: (value) => value!.trim().isEmpty ? '담당자명을 입력해주세요.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: '연락처', border: OutlineInputBorder()),
                validator: (value) => value!.trim().isEmpty ? '연락처를 입력해주세요.' : null,
              ),
              const SizedBox(height: 20),

              // 2. 위치 및 인증
              const _SectionTitle(title: '위치 정보 및 인증'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: '주소', border: OutlineInputBorder()),
                validator: (value) => value!.trim().isEmpty ? '주소를 입력해주세요.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _detailLocationController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: '화장실 위치 설명', hintText: '예: 2층 계단 옆, 매장 안쪽 복도 끝', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              
              // 📍 현장 위치 인증 버튼
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(_isLocationVerified ? Icons.check_circle : Icons.location_on, color: _isLocationVerified ? Colors.green : Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_isLocationVerified ? '현장 위치 인증 완료' : '현재 위치가 업소와 일치하는지 인증해주세요.',
                           style: TextStyle(fontWeight: FontWeight.bold, color: _isLocationVerified ? Colors.black : Colors.grey[700])),
                    ),
                    if (!_isLocationVerified)
                      ElevatedButton(
                        onPressed: _isLoadingLocation ? null : _verifyCurrentLocation,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                        child: _isLoadingLocation 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('인증하기', style: TextStyle(color: Colors.white)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. 안전 점검 항목
              const _SectionTitle(title: '안전 점검 항목'),
              const SizedBox(height: 8),
              CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('외부 CCTV가 설치되어 있어요'), value: _hasCctv, onChanged: (v) => setState(() => _hasCctv = v!)),
              CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('최근 점검 이력이 있어요'), value: _hasRecentInspection, onChanged: (v) => setState(() => _hasRecentInspection = v!)),
              CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('칸막이 구조가 비교적 안전해요'), value: _hasSeparatedStalls, onChanged: (v) => setState(() => _hasSeparatedStalls = v!)),
              CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('비상 호출 장치가 있어요'), value: _hasEmergencyBell, onChanged: (v) => setState(() => _hasEmergencyBell = v!)),
              const SizedBox(height: 20),

              // 4. 안전 시설 사진 업로드
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionTitle(title: '안전 시설 사진 첨부'),
                  TextButton.icon(
                    onPressed: _addPhoto,
                    icon: const Icon(Icons.add_a_photo, size: 18),
                    label: const Text('사진 추가'),
                  ),
                ],
              ),
              const Text('CCTV, 칸막이 등 안전을 증명할 수 있는 사진을 올려주세요.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 12),
              
              // 📸 사진 목록 가로 스크롤
              if (_photos.isEmpty)
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                  child: const Center(child: Text('등록된 사진이 없습니다.', style: TextStyle(color: Colors.grey))),
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: FileImage(_photos[index]), fit: BoxFit.cover)),
                          ),
                          Positioned(
                            top: 4, right: 16,
                            child: GestureDetector(
                              onTap: () => _removePhoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),

              // 5. 추가 메모
              const _SectionTitle(title: '추가 메모'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _memoController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: '추가 설명', hintText: '점검 주기, 특이사항, 관리자에게 전달할 내용을 적어주세요.', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 28),

              // 6. 제출 버튼
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(backgroundColor: colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('신청서 및 인증 데이터 전송', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
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
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
  }
}