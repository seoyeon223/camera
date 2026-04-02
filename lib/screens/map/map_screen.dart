import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  // 📍 지도가 처음 켜질 때 보여줄 기본 위치 (성신여대입구역 기준)
  LatLng _currentPosition = const LatLng(37.5926, 127.0164); 
  
  // 위치를 찾는 동안 로딩 화면을 보여주기 위한 변수
  bool _isLoading = true;

  // 🚽 1. 안전화장실 더미 데이터 (성북구 성신여대입구역 근처)
  final List<Map<String, dynamic>> _safeToilets = [
    {
      'name': '성신여대입구역 개찰구 화장실',
      'lat': 37.5926,
      'lng': 127.0164,
      'address': '서울특별시 성북구 동소문로 지하102',
      'details': '역사 내 위치, 경찰서 연계 비상벨 및 안심 스크린 설치 완료',
    },
    {
      'name': '돈암제일시장 안심 공중화장실',
      'lat': 37.5935,
      'lng': 127.0178,
      'address': '서울특별시 성북구 동소문로18길 12-3',
      'details': '시장 내 위치, 24시간 CCTV 작동 중 및 불법촬영 점검 완료',
    },
    {
      'name': '성북천 산책로 공중화장실',
      'lat': 37.5898,
      'lng': 127.0170,
      'address': '서울특별시 성북구 보문로 168 (성북천변)',
      'details': '여성 안심 화장실, 입구 밝은 조명 및 안심 거울 설치',
    },
    {
      'name': '성신여대 정문 인근 화장실',
      'lat': 37.5915,
      'lng': 127.0215,
      'address': '서울특별시 성북구 보문로34다길 2',
      'details': '야간 안심 보안등 설치, 지자체 집중 관리 구역',
    },
  ];
  

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() { _isLoading = false; });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() { _isLoading = false; });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() { _isLoading = false; });
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });

    _mapController.move(_currentPosition, 15.0);
  }

  // 💡 2. 마커를 눌렀을 때 실행될 하단 팝업창(BottomSheet) 함수
  void _showToiletDetails(Map<String, dynamic> toilet) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // 팝업창 위쪽 모서리를 둥글게
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내용물 크기만큼만 높이 차지
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.security, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    toilet['name'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 30), // 구분선
              Text('📍 위치: ${toilet['address']}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              Text('💡 상세정보: ${toilet['details']}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context), // 닫기 버튼 누르면 팝업창 내림
                  child: const Text('닫기', style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('안전화장실 지도'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.camera',
              ),
              MarkerLayer(
                markers: [
                  // 👤 내 위치 마커 (파란색 동그라미 아이콘으로 변경)
                  Marker(
                    point: _currentPosition,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
                  ),
                  
                  // 🚽 안전화장실 더미 데이터 마커들 (초록색 방패 모양 아이콘)
                  ..._safeToilets.map((toilet) {
                    return Marker(
                      point: LatLng(toilet['lat'], toilet['lng']),
                      width: 50,
                      height: 50,
                      // GestureDetector를 통해 터치 이벤트를 감지합니다.
                      child: GestureDetector(
                        onTap: () => _showToiletDetails(toilet), // 누르면 상세정보 팝업 띄우기
                        child: const Icon(Icons.security, color: Colors.green, size: 40),
                      ),
                    );
                  }), // 리스트로 변환해서 마커 목록에 추가
                ],
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController.move(_currentPosition, 15.0);
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}