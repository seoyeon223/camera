import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 🚀 Storage 패키지 추가됨

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
  final TextEditingController _descriptionController = TextEditingController(); 
  
  // 3. 제보 유형
  String? _selectedReportType;
  final List<String> _reportTypes = ['불법촬영 기기 발견', '불법촬영 의심', '이상한 Wi-Fi 포착', '안전화장실 등록 요청', '기타'];

  // 4. 사진 관련
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // 5. 제출 로딩 상태 (사진 업로드 시 대기 화면용)
  bool _isSubmitting = false;

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

  // 🚀 최종 제출 함수 (Firebase Storage 이미지 업로드 포함)
  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      if (!_isLocationVerified || _currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('현재 위치 인증을 진행해 주세요.')));
        return;
      }

      setState(() { _isSubmitting = true; }); // 제출 중 상태 켜기

      bool isSuccess = false; // 👈 추가: 데이터 전송 성공 여부를 명확히 추적하는 변수

      try {
        final String userUid = FirebaseAuth.instance.currentUser?.uid ?? '알_수_없음';
        String? imageUrl; // 업로드된 사진 URL을 담을 변수

        // // 📸 사진이 있다면 Firebase Storage에 업로드 (기존 코드 유지)
        // if (_imageFile != null) {
        //   // 파일명 생성: 현재 시간 + 유저ID (중복 방지)
        //   final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$userUid.jpg';
        //   final Reference storageRef = FirebaseStorage.instance.ref().child('reports/$fileName');
          
        //   // 사진 업로드 진행
        //   final UploadTask uploadTask = storageRef.putFile(_imageFile!);
        //   final TaskSnapshot snapshot = await uploadTask;
          
        //   // 업로드 완료 후 다운로드 URL 가져오기
        //   imageUrl = await snapshot.ref.getDownloadURL();
        // }

        // 📝 Firestore에 저장할 데이터 구성
        final reportData = {
          'reporter_uid': userUid, 
          'type': _selectedReportType,
          'description': _descriptionController.text, 
          'location_detail': _detailLocationController.text,
          'lat': _currentPosition?.latitude,
          'lng': _currentPosition?.longitude,
          if (imageUrl != null) 'imageUrl': imageUrl, // 사진이 업로드되었다면 URL 추가
        };
        
        debugPrint('서버로 전송될 제보 데이터: $reportData');
        
        // Firestore 'reports' 컬렉션에 데이터 저장
        // 👈 수정: 네트워크 지연 대비 Timeout(15초) 추가
        await FirebaseFirestore.instance.collection('reports').add({
           ...reportData,
          'createdAt': FieldValue.serverTimestamp(), 
          'status': '대기중', // 관리자 페이지 기준에 맞게 '대기중'으로 변경
        }).timeout(const Duration(seconds: 15)); 
        
        // 여기까지 에러 없이 도달했다면 제출 성공으로 간주합니다.
        isSuccess = true; 

      } catch (e) {
        debugPrint('제보 제출 에러: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('데이터 전송 중 오류가 발생했습니다. 네트워크를 확인하고 다시 시도해주세요.'))
          );
        }
      } finally {
        // 👈 수정: 성공/실패 여부에 따라 상태 업데이트와 화면 이동을 명확히 분리
        if (mounted) {
          if (isSuccess) {
            // 💡 성공 시: 로딩 상태를 강제로 끄지 않고(setState 미호출) 바로 화면을 교체합니다.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ReportCompleteScreen()),
            );
          } else {
            // ❌ 실패 시: 사용자가 재시도할 수 있도록 로딩 상태를 해제하고 버튼을 활성화합니다.
            setState(() { _isSubmitting = false; }); 
          }
        }
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

              // 3. 제보 유형 및 상세 상황 입력
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
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(hintText: '어떤 상황인지 자세하게 설명해 주세요.', border: OutlineInputBorder()),
                maxLines: 4, 
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
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover)),
                          Positioned(
                            right: 8, top: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                onPressed: () => setState(() => _imageFile = null), // 사진 삭제 버튼
                              ),
                            ),
                          )
                        ],
                      )
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
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isSubmitting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('제보 제출하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🎉 문구가 수정된 제보 완료 화면 위젯
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
              const Icon(Icons.favorite, color: Colors.redAccent, size: 80), // 감동적인 느낌을 위해 하트 아이콘으로 변경해봤어요!
              const SizedBox(height: 24),
              // 🚀 요청하신 멋진 문구로 변경 완료!
              const Text(
                '제출이 완료되었습니다.\n몰래카메라 없는 사회를 위해 노력해주셔서 감사합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
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