class CarouselSlide {
  const CarouselSlide({
    required this.image,
    required this.title,
    required this.subtitle,
  });

  final String image;
  final String title;
  final String subtitle;
}

class AppImages {
  static const carousel = [
    'assets/images/carousel/slide_01.jpeg',
    'assets/images/carousel/slide_02.jpeg',
    'assets/images/carousel/slide_03.jpeg',
    'assets/images/carousel/slide_04.jpeg',
    'assets/images/carousel/slide_05.jpeg',
    'assets/images/carousel/slide_06.jpeg',
    'assets/images/carousel/slide_07.jpeg',
    'assets/images/carousel/slide_08.jpeg',
    'assets/images/carousel/slide_09.jpeg',
    'assets/images/carousel/slide_10.jpeg',
    'assets/images/carousel/slide_11.jpeg',
    'assets/images/carousel/slide_12.jpeg',
    'assets/images/carousel/slide_13.jpeg',
    'assets/images/carousel/slide_14.jpeg',
    'assets/images/carousel/slide_15.jpeg',
    'assets/images/carousel/slide_16.jpeg',
    'assets/images/carousel/slide_17.jpeg',
  ];

  /// Featured login/splash slides with different app story copy.
  static const featuredSlides = [
    CarouselSlide(
      image: 'assets/images/carousel/slide_01.jpeg',
      title: 'Plan every Ghanaian ceremony',
      subtitle: 'Knocking, engagement, traditional, church and reception — all in one app.',
    ),
    CarouselSlide(
      image: 'assets/images/carousel/slide_03.jpeg',
      title: 'Invite your guests with ease',
      subtitle: 'Build your guest list, track RSVPs, and send digital invitations.',
    ),
    CarouselSlide(
      image: 'assets/images/carousel/slide_05.jpeg',
      title: 'Stay on budget, stay confident',
      subtitle: 'Track venue, décor, catering and more. Never lose sight of what’s left.',
    ),
    CarouselSlide(
      image: 'assets/images/carousel/slide_08.jpeg',
      title: 'Find trusted Ghana vendors',
      subtitle: 'Search décor, photographers, MCs and more — then request quotes instantly.',
    ),
    CarouselSlide(
      image: 'assets/images/carousel/slide_11.jpeg',
      title: 'Never miss a planning task',
      subtitle: 'Checklists for knocking, engagement and wedding day so nothing is forgotten.',
    ),
    CarouselSlide(
      image: 'assets/images/carousel/slide_14.jpeg',
      title: 'Save invitations & wedding photos',
      subtitle: 'Upload designs and memories so your wedding journey stays in one place.',
    ),
    CarouselSlide(
      image: 'assets/images/carousel/slide_17.jpeg',
      title: 'Welcome to WedPlan Ghana',
      subtitle: 'Sign in and start building the wedding you both deserve.',
    ),
  ];

  /// Registration page slides — onboarding for new couples & vendors.
  static const registerSlides = [
    CarouselSlide(
      image: 'assets/images/carousel/slide_02.jpeg',
      title: 'Create your free account',
      subtitle: 'Join thousands of Ghanaian couples planning knocking, engagement and wedding day.',
    ),
    CarouselSlide(
      image: 'assets/images/carousel/slide_04.jpeg',
      title: 'Are you a couple?',
      subtitle: 'Manage guests, budget, tasks and vendors from one beautiful place.',
    ),
    CarouselSlide(
      image: 'assets/images/carousel/slide_07.jpeg',
      title: 'Are you a vendor?',
      subtitle: 'Get discovered by couples, respond to quote requests, and grow your wedding business.',
    ),
    CarouselSlide(
      image: 'assets/images/carousel/slide_10.jpeg',
      title: 'Secure email verification',
      subtitle: 'We confirm your email so your wedding plans and client requests stay private.',
    ),
    CarouselSlide(
      image: 'assets/images/carousel/slide_13.jpeg',
      title: 'Start planning today',
      subtitle: 'Registration only takes a minute — then your wedding journey begins.',
    ),
  ];

  static List<String> get featured => featuredSlides.map((s) => s.image).toList();
}
