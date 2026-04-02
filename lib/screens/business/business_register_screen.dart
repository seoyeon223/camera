import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 👈 추가됨: Firebase Storage
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

  // 📸 사진 업로드 관련 변수
  final List<File> _photos = [];
  final ImagePicker _picker = ImagePicker();
  
  // 🚀 폼 제출 로딩 상태 변수 (사진 업로드 중 중복 클릭 방지)
  bool _isSubmitting = false;

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

  // 📸 사진 추가 함수
  Future<void> _addPhoto() async {
    // TIP: imageQuality를 낮춰서 업로드 속도와 스토리지 비용을 절감할 수 있습니다.
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
                final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (pickedFile != null) setState(() => _photos.add(File(pickedFile.path)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택하기'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
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

  // 🚀 최종 제출 함수 (수정됨: Storage 업로드 로직 추가)
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLocationVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('현장 위치 인증을 진행해 주세요.')));
      return;
    }

    // if (_photos.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('안전 시설 사진을 최소 1장 이상 첨부해 주세요.')));
    //   return;
    // }

    bool isSuccess = false;

    try {
      final String userUid = FirebaseAuth.instance.currentUser?.uid ?? '알_수_없음';
      
      // // 1. Firebase Storage에 사진 업로드 및 URL 획득
      // List<String> uploadedPhotoUrls = [];
      
      // for (int i = 0; i < _photos.length; i++) {
      //   File photo = _photos[i];
        
      //   // 고유한 파일명 생성 (UID + 현재시간 + 인덱스)
      //   String fileName = 'business_photos/${userUid}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      //   Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        
      //   // 파일 업로드 대기
      //   UploadTask uploadTask = storageRef.putFile(photo);
      //   TaskSnapshot snapshot = await uploadTask;
        
      //   // 업로드된 파일의 다운로드 URL 가져오기
      //   String downloadUrl = await snapshot.ref.getDownloadURL();
      //   uploadedPhotoUrls.add(downloadUrl);
      // }

      // 2. 등록 데이터 묶기 (URL 리스트 포함)
      final businessData = {
        'uploader_uid': userUid,
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
        //'photo_urls': uploadedPhotoUrls, // 👈 관리자 페이지에서 렌더링할 URL 리스트
        'createdAt': FieldValue.serverTimestamp(),
        'status': '심사중',
      };

      // 3. Firestore에 데이터 저장
      await FirebaseFirestore.instance
          .collection('businesses')
          .add(businessData)
          .timeout(const Duration(seconds: 15)); 

      // 에러 없이 여기까지 도달했다면 성공으로 간주합니다.
      isSuccess = true;

      // 4. 성공 화면으로 이동 (현재 화면을 성공 화면으로 교체)
      } catch (e) {
      debugPrint('제출 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('데이터 전송 중 오류가 발생했습니다. 네트워크 상태를 확인해주세요.')),
        );
      }
    } finally {
      // 화면 이동 및 상태 관리 로직
      if (mounted) {
        if (isSuccess) {
          // ✅ 성공 시: 로딩 상태를 강제로 끄지 않고 화면을 덮어씌웁니다. 
          // (화면 전환 중 로딩 인디케이터가 깜빡거리며 사라지는 것을 방지하여 UI가 훨씬 자연스럽습니다.)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BusinessRegisterSuccessScreen()),
          );
        } else {
          // ❌ 실패 시: 사용자가 다시 시도할 수 있도록 로딩 상태를 해제하여 버튼을 활성화합니다.
          setState(() { _isSubmitting = false; });
        }
      }
      
    } 
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('업소 등록 신청')),
      body: SafeArea(
        // 로딩 중일 때 터치 이벤트를 막아주는 IgnorePointer
        child: IgnorePointer(
          ignoring: _isSubmitting,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // (이하 UI는 기존 코드와 동일합니다)
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
                const Text('C초TV, 칸막이 등 안전을 증명할 수 있는 사진을 올려주세요.', style: TextStyle(fontSize: 13, color: Colors.grey)),
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

                // 6. 제출 버튼 (업데이트됨: 로딩 인디케이터 추가)
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(backgroundColor: colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isSubmitting 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('신청서 및 인증 데이터 전송', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
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

// ----------------------------------------------------------------------
// 🏆 새롭게 추가된 '제출 완료 화면' 위젯입니다.
// 이 코드를 같은 파일 하단에 넣거나, 새로운 파일(예: success_screen.dart)로 분리해서 import 하시면 됩니다.
// ----------------------------------------------------------------------
class BusinessRegisterSuccessScreen extends StatelessWidget {
  const BusinessRegisterSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 성공 아이콘
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 80),
                ),
                const SizedBox(height: 32),
                
                // 완료 메시지
                Text(
                  '신청이 완료되었습니다!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  '업소 등록 신청이 성공적으로 접수되었습니다.\n관리자가 사진과 위치를 검토한 후 지도에 반영합니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
                ),
                const SizedBox(height: 48),
                
                // 홈으로 돌아가기 버튼
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      // 네비게이션 스택을 비우고 메인 화면으로 돌아갑니다. (경로는 프로젝트에 맞게 수정하세요)
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('메인으로 돌아가기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}