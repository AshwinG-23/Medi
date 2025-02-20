import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms of Service'),
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
              'Terms of Service',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Effective Date: 12 Feb 2025\n\n'
              '1. Introduction\n'
              'Welcome to MediSync, a healthcare app that connects you with nearby healthcare centers and helps you manage your health. By accessing or using the App, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree, please refrain from using the App.\n\n'
              '2. User Eligibility\n'
              'You must be at least 18 years old or the legal age in your jurisdiction to use the App. If you are under the required age, you must have permission from a parent or guardian to use the App.\n\n'
              '3. Account Creation and Maintenance\n'
              'To use the App, you may need to create an account by providing accurate and up-to-date information. You are responsible for maintaining the confidentiality of your login credentials and for all activities under your account.\n\n'
              '4. User Responsibilities\n'
              'You agree to use the App only for lawful purposes and in accordance with applicable local, state, and international laws.\n'
              'You will not engage in any behavior that could harm the App’s functionality, security, or reputation.\n'
              'You agree not to misuse or intentionally harm any healthcare providers, facilities, or services listed on the App.\n\n'
              '5. Use of Location Data\n'
              'By using the App, you consent to the collection and use of your location data to provide you with relevant information about nearby healthcare centers, such as hospitals, clinics, and doctors. You can disable location services at any time through your device settings, but this may affect the App’s functionality.\n\n'
              '6. Health Information\n'
              'The App provides tools and resources for health management, but does not replace professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.\n\n'
              '7. Fees and Payments\n'
              'If the App offers paid features, such as premium services or access to specialized consultations, you agree to pay the specified fees. Payment terms will be outlined in the relevant section of the App.\n\n'
              '8. Data Usage and Privacy\n'
              'We take your privacy seriously. Our Privacy Policy outlines how we collect, use, and protect your personal and health data.\n\n'
              '9. Updates to the App and Service\n'
              'We may update the App and its features regularly. You agree to install such updates to continue using the App efficiently.\n\n'
              '10. Termination\n'
              'We reserve the right to suspend or terminate your account if you violate these Terms of Service. You can also delete your account at any time through the settings menu.\n\n'
              '11. Limitation of Liability\n'
              'The App is provided "as is," and we do not guarantee the accuracy, reliability, or completeness of the information provided. We are not liable for any damages arising from the use of the App, including loss of data or health-related issues.\n\n'
              '12. Dispute Resolution\n'
              'Any disputes regarding these Terms of Service shall be resolved through arbitration in accordance with [Insert Jurisdiction] laws.\n\n'
              '13. Changes to Terms of Service\n'
              'We may update these Terms from time to time. You will be notified of any significant changes, and continued use of the App will constitute acceptance of the updated terms.\n\n'
              '14. Contact Information\n'
              'If you have any questions about these Terms of Service, please contact us at [Insert Contact Information].',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
