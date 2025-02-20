import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/logo.png', // Replace with your app logo asset
              width: 100,
              height: 100,
            ),
            SizedBox(height: 20),
            Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Effective Date: 12 Feb 2025\n\n'
              'At MediSync, we value your privacy and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your data.\n\n'
              '1. Information We Collect\n'
              'Personal Information: When you create an account, we may collect information such as your name, email address, phone number, and payment details.\n'
              'Health Information: You may voluntarily input health-related information (e.g., medical conditions, medications, allergies) to personalize your experience.\n'
              'Location Data: To help you find nearby healthcare centers, we collect your precise location using GPS or IP address. You can opt-out of location tracking by disabling it in your device settings.\n\n'
              '2. How We Use Your Information\n'
              'Location Data: We use your location to provide you with relevant healthcare center suggestions based on your proximity.\n'
              'Health Data: We may use your health information to offer personalized health recommendations or connect you with medical professionals.\n'
              'Account Information: We use your personal information to manage your account and communicate important information regarding updates or services.\n'
              'Improvement of Services: We may analyze aggregated data to improve the App and offer better services.\n\n'
              '3. Data Sharing and Disclosure\n'
              'We do not share your personal or health data with third parties, except:\n'
              'Healthcare Providers: If you choose to share your data with a specific healthcare provider or center, we may provide them with the necessary information.\n'
              'Service Providers: We may use third-party services (e.g., cloud storage or payment processors) to operate the App, but they are required to maintain your data confidentiality.\n'
              'Legal Requirements: We may disclose information if required by law or in response to valid requests by governmental authorities.\n\n'
              '4. Data Retention\n'
              'We retain your data for as long as needed to provide the services and comply with legal obligations. You can request to delete your account or specific data at any time through the App.\n\n'
              '5. Data Security\n'
              'We implement appropriate technical and organizational measures to protect your personal and health data, including encryption and secure servers. However, please be aware that no system is completely secure, and we cannot guarantee the complete security of your information.\n\n'
              '6. Your Rights\n'
              'Depending on your location, you may have certain rights regarding your data, including:\n'
              'Access: The right to access the personal data we hold about you.\n'
              'Correction: The right to request updates or corrections to your data.\n'
              'Deletion: The right to request the deletion of your personal and health data.\n'
              'Withdraw Consent: The right to withdraw consent for processing your data.\n'
              'To exercise these rights, please contact us at [Insert Contact Information].\n\n'
              '7. Children\'s Privacy\n'
              'The App is not intended for children under the age of 13 (or 16 in some jurisdictions). We do not knowingly collect personal information from minors. If we discover that a minor has provided us with data, we will delete it as soon as possible.\n\n'
              '8. Changes to This Privacy Policy\n'
              'We may update this Privacy Policy from time to time. When changes are made, the new policy will be posted, and the effective date will be updated. Continued use of the App after the update constitutes your acceptance of the new policy.\n\n'
              '9. Contact Information\n'
              'For any questions or concerns regarding this Privacy Policy, please contact us.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
