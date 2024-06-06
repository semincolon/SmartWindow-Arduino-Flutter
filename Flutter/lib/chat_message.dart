import 'package:flutter/material.dart';
//https://here4you.tistory.com/147
const String _name = "You";

// 리스브뷰에 추가될 메시지 위젯
class ChatMessage extends StatelessWidget {
  final String text; // 출력할 메시지
  final AnimationController animationController; // 리스트뷰에 등록될 때 보여질 효과

  const ChatMessage({super.key, required this.text, required this.animationController});

  @override
  Widget build(BuildContext context) {
    // 위젯에 애니메이션을 발생하기 위해 SizeTransition을 추가
    return SizeTransition(
      // 사용할 애니메이션 효과 설정
      sizeFactor:
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
      axisAlignment: 0.0,
      // 리스트뷰에 추가될 컨테이너 위젯
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              // 사용자명의 첫번째 글자를 서클 아바타로 표시
              child: CircleAvatar(child: Text(_name[0])),
            ),
            Expanded(
              // 컬럼 추가
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 사용자명을 subhead 테마로 출력
                  Text(_name, style: Theme.of(context).textTheme.titleMedium),
                  // 입력받은 메시지 출력
                  Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    child: Text(text),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}