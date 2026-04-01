import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. 위치 및 검증 관련
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isLocationVerified = false;

  // 2. 입력 컨트롤러
  final TextEditingController _detailLocationController = TextEditingController();
  // 💡 기존의 '기타' 전용 컨트롤러를 '상세 설명' 범용 컨트롤러로 변경했습니다.
  final TextEditingController _descriptionController = TextEditingController(); 
  
  // 3. 제보 유형
  String? _selectedReportType;
  final List<String> _reportTypes = ['불법촬영 기기 발견', '불법촬영 의심', '이상한 Wi-Fi 포착', '안전화장실 등록 요청', '기타'];

  // 4. 사진 관련
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _detailLocationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 📍 사용자가 버튼을 눌렀을 때 내부 위치 수집 및 검증 진행
  Future<void> _verifyCurrentLocation() async {
    if (_detailLocationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('상세 위치를 먼저 입력해 주세요!')));
      return;
    }

    setState(() { _isLoadingLocation = true; });
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _isLocationVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('위치 인증이 완료되었습니다.')));
    } catch (e) {
      debugPrint('위치 수집 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('위치 인증에 실패했습니다. 권한을 확인해주세요.')));
    } finally {
      setState(() { _isLoadingLocation = false; });
    }
  }

  // 📸 카메라 실행 전 가이드 제공
  Future<void> _showPhotoGuide() async {
    bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📢 촬영 전 주변 확인'),
        content: const Text(
          '현재 화장실 내부에 다른 사람이 없나요?\n\n'
          '타인의 프라이버시를 보호하기 위해 사람이 없을 때만 촬영해 주세요. '
          '주변에 사람이 있다면 사진 없이 위치와 텍스트로만 제보하는 것이 안전합니다.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('확인했습니다', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (proceed == true) {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) setState(() { _imageFile = File(pickedFile.path); });
    }
  }

  // 🚀 최종 제출 함수
  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      if (!_isLocationVerified || _currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('현재 위치 인증을 진행해 주세요.')));
        return;
      }

      final String userUid = FirebaseAuth.instance.currentUser?.uid ?? '알_수_없음';

      final reportData = {
        'reporter_uid': userUid, 
        'type': _selectedReportType,
        'description': _descriptionController.text, // 💡 상세 내용이 무조건 저장되도록 수정했습니다.
        'location_detail': _detailLocationController.text,
        'lat': _currentPosition?.latitude,
        'lng': _currentPosition?.longitude,
      };
      
      debugPrint('서버로 전송될 제보 데이터: $reportData');
      await FirebaseFirestore.instance.collection('reports').add({
         ...reportData,
        'createdAt': FieldValue.serverTimestamp(), 
        'status': '검토중', 
      });
            
      // 💡 제출이 완료되면 현재 화면을 지우고 완료 화면으로 교체(pushReplacement)합니다.
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ReportCompleteScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('안전 제보하기'), elevation: 0),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상세 위치 입력
              const Text('1. 자세한 위치를 입력해주세요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _detailLocationController,
                decoration: const InputDecoration(hintText: '예: 백화점 2층 화장실 칸막이 아래', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? '상세 위치를 적어주세요.' : null,
              ),
              const SizedBox(height: 25),

              // 2. 위치 인증 버튼
              const Text('2. 현장 위치 인증', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(_isLocationVerified ? Icons.check_circle : Icons.location_on, 
                         color: _isLocationVerified ? Colors.green : Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_isLocationVerified ? '현재 위치 인증 완료' : '현장 검증을 위해 위치를 인증해 주세요.',
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
              const SizedBox(height: 25),

              // 3. 제보 유형 및 상세 상황 입력 (기능 업데이트)
              const Text('3. 무슨 일이 있었나요?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                value: _selectedReportType,
                hint: const Text('제보 유형을 선택해주세요'),
                items: _reportTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _selectedReportType = v),
                validator: (v) => v == null ? '유형을 선택해주세요.' : null,
              ),
              const SizedBox(height: 15),
              // 💡 '기타' 조건문(if)을 없애고 항상 보여지도록 밖으로 꺼냈습니다.
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(hintText: '어떤 상황인지 자세하게 설명해 주세요.', border: OutlineInputBorder()),
                maxLines: 4, // 입력칸을 좀 더 넓게 만들었습니다.
                validator: (v) => v!.isEmpty ? '상세 내용을 입력해주세요.' : null,
              ),
              const SizedBox(height: 25),

              // 4. 사진 가이드 및 업로드
              const Text('4. 현장 사진 (선택 사항)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              InkWell(
                onTap: _showPhotoGuide,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _imageFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('가이드 확인 후 촬영하기', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 35),

              // 5. 제출 버튼
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('제보 제출하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🎉 새로 추가된 제보 완료 화면 위젯
class ReportCompleteScreen extends StatelessWidget {
  const ReportCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('제보 완료'), elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 성공을 나타내는 체크 아이콘
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              const Text(
                '제보가 성공적으로 접수되었습니다!', 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 16),
              const Text(
                '안전한 환경을 만드는 데 참여해 주셔서 감사합니다.\n관리자 검토 후 조치될 예정입니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  // 확인 버튼을 누르면 이전 화면(보통 홈 화면)으로 돌아갑니다.
                  onPressed: () => Navigator.pop(context), 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text('확인 (홈으로 돌아가기)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}