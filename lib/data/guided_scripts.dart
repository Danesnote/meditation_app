/// 가이드 문장 하나. [at]은 명상 전체 길이 중 읽기 시작할 위치(0.0 ~ 1.0).
class GuidedPrompt {
  const GuidedPrompt(this.at, this.text);

  final double at;
  final String text;
}

/// 음성으로 읽어 주는 가이드 명상.
///
/// 문장 위치를 비율로 정해 두어서, 3분이든 30분이든 같은 흐름으로 진행된다.
enum GuidedMeditation {
  none('사용 안 함', []),
  breath('호흡 알아차림', [
    GuidedPrompt(0, '편안하게 앉아 눈을 감습니다. 어깨의 힘을 빼고, 자연스럽게 숨을 쉽니다.'),
    GuidedPrompt(0.1, '코끝으로 들어오고 나가는 숨에 주의를 둡니다. 숨을 조절하지 않고, 그대로 바라봅니다.'),
    GuidedPrompt(0.35, '생각이 떠오르면, 떠올랐다는 것만 알아차리고 다시 숨으로 돌아옵니다.'),
    GuidedPrompt(0.6, '들숨과 날숨 사이의 작은 멈춤도 느껴 봅니다.'),
    GuidedPrompt(0.85, '지금 이 순간, 숨 쉬고 있는 나를 그대로 느낍니다.'),
    GuidedPrompt(0.96, '천천히 주의를 몸 전체로 넓히고, 준비가 되면 눈을 뜹니다.'),
  ]),
  bodyScan('바디 스캔', [
    GuidedPrompt(0, '편안한 자세로 눈을 감고, 몸이 바닥에 닿는 느낌을 느껴 봅니다.'),
    GuidedPrompt(0.08, '주의를 발끝으로 가져갑니다. 발가락, 발바닥, 발등의 감각을 느껴 봅니다.'),
    GuidedPrompt(0.22, '주의를 종아리와 무릎, 허벅지로 천천히 옮깁니다.'),
    GuidedPrompt(0.38, '골반과 배를 느껴 봅니다. 숨 쉴 때 배가 오르내리는 것을 바라봅니다.'),
    GuidedPrompt(0.52, '가슴과 등, 어깨로 주의를 옮깁니다. 긴장이 있다면 숨과 함께 내려놓습니다.'),
    GuidedPrompt(0.66, '팔과 손, 손가락 끝까지 느껴 봅니다.'),
    GuidedPrompt(0.78, '목과 얼굴, 턱과 눈 주변의 힘을 풀어 줍니다.'),
    GuidedPrompt(0.88, '이제 몸 전체를 하나로 느껴 봅니다.'),
    GuidedPrompt(0.96, '손가락과 발가락을 살짝 움직이고, 준비가 되면 눈을 뜹니다.'),
  ]),
  lovingKindness('자애 명상', [
    GuidedPrompt(0, '편안하게 앉아 눈을 감고, 몇 번 깊게 숨을 쉽니다.'),
    GuidedPrompt(0.1, '마음속으로 나에게 말해 봅니다. 내가 평안하기를. 내가 건강하기를. 내가 행복하기를.'),
    GuidedPrompt(0.3, '소중한 사람 한 명을 떠올립니다. 당신이 평안하기를. 당신이 행복하기를.'),
    GuidedPrompt(0.5, '잘 알지 못하는 사람을 떠올립니다. 그 사람도 평안하고 행복하기를 바랍니다.'),
    GuidedPrompt(0.7, '어려운 관계의 사람을 떠올려 봅니다. 할 수 있는 만큼만, 그 사람도 평안하기를 바랍니다.'),
    GuidedPrompt(0.85, '이제 모든 존재에게 마음을 넓힙니다. 모든 존재가 평안하고 행복하기를.'),
    GuidedPrompt(0.96, '따뜻한 마음을 간직한 채, 준비가 되면 눈을 뜹니다.'),
  ]);

  const GuidedMeditation(this.label, this.prompts);

  final String label;
  final List<GuidedPrompt> prompts;
}
