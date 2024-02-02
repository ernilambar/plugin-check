Feature: Test that the WP-CLI command works for multile files plugin.

  Scenario: Check Custom Plugin with multiple files
    Given a WP install with the Plugin Check plugin
    And an empty wp-content/plugins/foo-multiple directory
    And an empty wp-content/plugins/foo-multiple/subdirectory directory
    And a wp-content/plugins/foo-multiple/foo-multiple.php file:
      """
      <?php
      /**
       * Plugin Name: Foo Multiple
       * Plugin URI:  https://example.com
       * Description:
       * Version:     0.1.0
       * Author:
       * Author URI:
       * License:     GPL-2.0+
       * License URI: http://www.gnu.org/licenses/gpl-2.0.txt
       * Text Domain: foo-multiple-text-domain
       * Domain Path: /languages
       */

      add_action( 'init', function() {
        $text_domain = 'test-plugin-check-errors';
        $message = __( 'Hello World!', $text_domain );
        echo $message;
      } );
      """
    And a wp-content/plugins/foo-multiple/readme.txt file:
      """
      === Foo Multiple ===

      Contributors:      wordpressdotorg
      Requires at least: 6.0
      Tested up to:      6.1
      Requires PHP:      5.6
      Stable tag:        trunk
      License:           Oculus VR Inc. Software Development Kit License
      License URI:       https://www.gnu.org/licenses/gpl-2.0.html
      Tags:              performance, testing, security

      Here is a short description of the plugin.
      """
    And a wp-content/plugins/foo-multiple/subdirectory/bar.php file:
      """
      <?php
      $value = 1;
      echo $value;
      """

    When I run the WP-CLI command `plugin check foo-multiple`
    Then STDOUT should contain:
      """
      WordPress.WP.I18n.NonSingularStringLiteralDomain
      """
    And STDOUT should not contain:
      """
      no_plugin_readme
      """
    And STDOUT should contain:
      """
      stable_tag_mismatch
      """
    And STDOUT should contain:
      """
      All output should be run through an escaping function
      """
    And STDOUT should contain:
      """
      textdomain_mismatch
      """
    And STDOUT should contain:
      """
      FILE: subdirectory/bar.php
      """
    And STDOUT should not contain:
      """
      trademarked_term
      """

    When I run the WP-CLI command `plugin check foo-multiple --exclude-directories=subdirectory`
    Then STDOUT should not contain:
      """
      FILE: subdirectory/bar.php
      """

    When I run the WP-CLI command `plugin check foo-multiple --format=csv --fields=line,column,type,code`
    Then STDOUT should contain:
      """
      line,column,type,code
      0,0,WARNING,textdomain_mismatch
      """

    When I run the WP-CLI command `plugin check foo-multiple --ignore-warnings`
    Then STDOUT should not contain:
      """
      textdomain_mismatch
      """

    When I run the WP-CLI command `plugin check foo-multiple --ignore-errors`
    Then STDOUT should not contain:
      """
      stable_tag_mismatch
      """
