Feature: Test that the WP-CLI command works.

  Scenario: Check a non-existent plugin
    Given a WP install with the Plugin Check plugin

    When I try the WP-CLI command `plugin check foo-bar`
    Then STDERR should contain:
      """
      Plugin with slug foo-bar is not installed.
      """

  Scenario: Check custom single file plugin
    Given a WP install with the Plugin Check plugin
    And a wp-content/plugins/foo-single.php file:
      """
      <?php
      /**
       * Plugin Name: Foo Single
       * Plugin URI: https://example.com
       * Description: Custom plugin.
       * Version: 0.1.0
       * Author: WordPress Performance Team
       * Author URI: https://make.wordpress.org/performance/
       * License: GPL-2.0+
       * License URI: http://www.gnu.org/licenses/gpl-2.0.txt
       */

      add_action(
        'init',
        function () {
          $number = mt_rand( 10, 100 );
          echo $number;
        }
      );
      """

    When I run the WP-CLI command `plugin check foo-single.php`
    Then STDOUT should contain:
      """
      mt_rand() is discouraged.
      """
    And STDOUT should not contain:
      """
      no_plugin_readme
      """
    And STDOUT should not contain:
      """
      trademarked_term
      """
    And STDOUT should contain:
      """
      All output should be run through an escaping function
      """

    When I run the WP-CLI command `plugin check foo-single.php --format=csv`
    Then STDOUT should contain:
      """
      line,column,type,code,message
      16,15,ERROR,WordPress.WP.AlternativeFunctions.rand_mt_rand,"mt_rand() is discouraged. Use the far less predictable wp_rand() instead."
      """

    When I run the WP-CLI command `plugin check foo-single.php --format=csv --fields=line,column,code`
    Then STDOUT should contain:
      """
      line,column,code
      16,15,WordPress.WP.AlternativeFunctions.rand_mt_rand
      """

    When I run the WP-CLI command `plugin check foo-single.php --format=json`
    Then STDOUT should contain:
      """
      {"line":16,"column":15,"type":"ERROR","code":"WordPress.WP.AlternativeFunctions.rand_mt_rand","message":"mt_rand() is discouraged. Use the far less predictable wp_rand() instead."}
      """

    When I run the WP-CLI command `plugin check foo-single.php --ignore-errors`
    Then STDOUT should be empty

    When I run the WP-CLI command `plugin check foo-single.php --ignore-warnings`
    Then STDOUT should not be empty

    When I run the WP-CLI command `plugin check foo-single.php --checks=plugin_review_phpcs`
    Then STDOUT should contain:
      """
      WordPress.WP.AlternativeFunctions.rand_mt_rand
      """
    And STDOUT should not contain:
      """
      WordPress.Security.EscapeOutput.OutputNotEscaped
      """

    When I run the WP-CLI command `plugin check foo-single.php --exclude-checks=late_escaping`
    Then STDOUT should not contain:
      """
      WordPress.Security.EscapeOutput.OutputNotEscaped
      """
    And STDOUT should contain:
      """
      WordPress.WP.AlternativeFunctions.rand_mt_rand
      """
    When I run the WP-CLI command `plugin check foo-single.php --categories=security`
    Then STDOUT should contain:
      """
      WordPress.Security.EscapeOutput.OutputNotEscaped
      """
    And STDOUT should not contain:
      """
      WordPress.WP.AlternativeFunctions.rand_mt_rand
      """
    When I run the WP-CLI command `plugin check foo-single.php --checks=plugin_review_phpcs,late_escaping --exclude-checks=late_escaping`
    Then STDOUT should contain:
      """
      WordPress.WP.AlternativeFunctions.rand_mt_rand
      """
    And STDOUT should not contain:
      """
      WordPress.Security.EscapeOutput.OutputNotEscaped
      """

  Scenario: Exclude directories in plugin check
    Given a WP install with the Plugin Check plugin
    And an empty wp-content/plugins/foo-plugin directory
    And an empty wp-content/plugins/foo-plugin/subdirectory directory
    And a wp-content/plugins/foo-plugin/foo-plugin.php file:
      """
      <?php
      /**
       * Plugin Name: Foo Plugin
       * Plugin URI:  https://example.com
       * Description:
       * Version:     0.1.0
       * Author:
       * Author URI:
       * License:     GPL-2.0+
       * License URI: http://www.gnu.org/licenses/gpl-2.0.txt
       * Text Domain: foo-plugin
       * Domain Path: /languages
       */

      """
    And a wp-content/plugins/foo-plugin/subdirectory/bar.php file:
      """
      <?php
      $value = 1;
      echo $value;
      """

    When I run the WP-CLI command `plugin check foo-plugin`
    Then STDOUT should contain:
      """
      FILE: subdirectory/bar.php
      """

    When I run the WP-CLI command `plugin check foo-plugin --exclude-directories=subdirectory`
    Then STDOUT should not contain:
      """
      FILE: subdirectory/bar.php
      """

  Scenario: Exclude files in plugin check
    Given a WP install with the Plugin Check plugin
    And an empty wp-content/plugins/foo-plugin directory
    And an empty wp-content/plugins/foo-plugin/subdirectory directory
    And a wp-content/plugins/foo-plugin/foo-plugin.php file:
      """
      <?php
      /**
       * Plugin Name: Foo Plugin
       * Plugin URI:  https://example.com
       * Description:
       * Version:     0.1.0
       * Author:
       * Author URI:
       * License:     GPL-2.0+
       * License URI: http://www.gnu.org/licenses/gpl-2.0.txt
       * Text Domain: foo-plugin
       * Domain Path: /languages
       */

      """
    And a wp-content/plugins/foo-plugin/bar.php file:
      """
      <?php
      $value = 1;
      echo $value;
      """
    And a wp-content/plugins/foo-plugin/foobar.php file:
      """
      <?php
      $value = 1;
      echo $value;
      """
    And a wp-content/plugins/foo-plugin/subdirectory/error.php file:
      """
      <?php
      $value = 1;
      echo $value;
      """
    When I run the WP-CLI command `plugin check foo-plugin`
    Then STDOUT should contain:
      """
      FILE: bar.php
      """
    And STDOUT should contain:
      """
      FILE: foobar.php
      """

    When I run the WP-CLI command `plugin check foo-plugin --exclude-files=bar.php`
    Then STDOUT should contain:
      """
      FILE: foobar.php
      """
    Then STDOUT should not contain:
      """
      FILE: bar.php
      """

    When I run the WP-CLI command `plugin check foo-plugin --exclude-files=subdirectory/error.php`
    Then STDOUT should not contain:
      """
      FILE: subdirectory/error.php
      """

  Scenario: Perform runtime check
    Given a WP install with the Plugin Check plugin
    And a wp-content/plugins/foo-single.php file:
      """
      <?php
      /**
       * Plugin Name: Foo Single
       * Plugin URI: https://example.com
       * Description: Custom plugin.
       * Version: 0.1.0
       * Author: WordPress Performance Team
       * Author URI: https://make.wordpress.org/performance/
       * License: GPL-2.0+
       * License URI: http://www.gnu.org/licenses/gpl-2.0.txt
       */

      add_action(
        'init',
        function () {
          $number = mt_rand( 10, 100 );
          echo $number;
        }
      );
      """

    When I run the WP-CLI command `plugin check foo-single.php --require=./wp-content/plugins/plugin-check/cli.php`
    Then STDOUT should contain:
      """
      mt_rand() is discouraged.
      """

  Scenario: Check a plugin from external location
    Given a WP install with the Plugin Check plugin
    And an empty external-folder/foo-plugin directory
    And a external-folder/foo-plugin/foo-plugin.php file:
      """
      <?php
      /**
       * Plugin Name: Foo Plugin
       * Plugin URI:  https://example.com
       * Description:
       * Version:     0.1.0
       * Author:
       * Author URI:
       * License:     GPL-2.0+
       * License URI: http://www.gnu.org/licenses/gpl-2.0.txt
       * Text Domain: foo-plugin
       * Domain Path: /languages
       */

      """

    When I run the WP-CLI command `plugin check {RUN_DIR}/external-folder/foo-plugin`
    Then STDERR should be empty
    And STDOUT should contain:
      """
      trademarked_term
      """
    And STDOUT should contain:
      """
      no_plugin_readme
      """

  Scenario: Check a plugin with extra checks
    Given a WP install with the Plugin Check plugin
    And a wp-content/plugins/pcp-addon/pcp-addon.php file:
      """
      <?php
      /**
      * Plugin Name: PCP Addon
      * Plugin URI: https://example.com
      * Description: Plugin Check addon.
      * Version: 0.1.0
      * Author: WordPress Performance Team
      * Author URI: https://make.wordpress.org/performance/
      * License: GPL-2.0+
      * License URI: http://www.gnu.org/licenses/gpl-2.0.txt
      * Requires Plugins: plugin-check
      */

      use WordPress\Plugin_Check\Checker\Check_Result;
      use WordPress\Plugin_Check\Checker\Checks\Abstract_File_Check;
      use WordPress\Plugin_Check\Checker\Checks\Abstract_PHP_CodeSniffer_Check;
      use WordPress\Plugin_Check\Traits\Amend_Check_Result;
      use WordPress\Plugin_Check\Traits\Stable_Check;

      if ( ! class_exists( WordPress\Plugin_Check\Plugin_Main::class, false ) ) {
        require_once WP_PLUGIN_DIR . '/plugin-check/vendor/autoload.php';
      }

      class Prohibited_Text_Check extends Abstract_File_Check {

        use Amend_Check_Result;
        use Stable_Check;

        public function get_categories() {
          return array( 'general' );
        }

        protected function check_files( Check_Result $result, array $files ) {
          $php_files = self::filter_files_by_extension( $files, 'php' );
          $file      = self::file_preg_match( '#I\sam\sbad#', $php_files );
          if ( $file ) {
            $this->add_result_error_for_file(
              $result,
              __( 'Prohibited text found.', 'pcp-addon' ),
              'prohibited_text_detected',
              $file,
              0,
              0,
              8
            );
          }
        }
      }

      class PostsPerPage_Check extends Abstract_PHP_CodeSniffer_Check {

        use Stable_Check;

        public function get_categories() {
          return array( 'general' );
        }

        protected function get_args() {
          return array(
            'extensions' => 'php',
            'standard'   => plugin_dir_path( __FILE__ ) . 'postsperpage.xml',
          );
        }
      }

      add_filter(
        'wp_plugin_check_checks',
        function ( array $checks ) {
          return array_merge(
            $checks,
            array(
              'prohibited_text' => new Prohibited_Text_Check(),
              'postsperpage'    => new PostsPerPage_Check(),
            )
          );
        }
      );
      """
    And a wp-content/plugins/pcp-addon/postsperpage.xml file:
      """
      <?xml version="1.0"?>
      <ruleset xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="PCPAddon" xsi:noNamespaceSchemaLocation="https://raw.githubusercontent.com/squizlabs/PHP_CodeSniffer/master/phpcs.xsd">
        <rule ref="WordPress.WP.PostsPerPage">
          <severity>9</severity>
        </rule>
      </ruleset>
      """
    And I run the WP-CLI command `plugin activate pcp-addon`
    And a wp-content/plugins/foo-sample/foo-sample.php file:
      """
      <?php
      /**
       * Plugin Name: Foo Sample
       * Plugin URI: https://example.com
       * Description: Sample plugin.
       * Version: 0.1.0
       * Author: WordPress Performance Team
       * Author URI: https://make.wordpress.org/performance/
       * License: GPL-2.0+
       * License URI: http://www.gnu.org/licenses/gpl-2.0.txt
       */

      add_action(
        'init',
        function () {
          echo absint( mt_rand( 10, 100 ) );

          echo 'I am bad'; // This should trigger the error.

          $qargs = array(
            'post_type'      => 'post',
            'post_status'    => 'publish',
            'posts_per_page' => 1000,
            'no_found_rows'  => true,
          );
        }
      );
      """

    When I run the WP-CLI command `plugin check foo-sample`
    Then STDOUT should contain:
      """
      WordPress.WP.AlternativeFunctions.rand_mt_rand
      """
    And STDOUT should contain:
      """
      prohibited_text_detected
      """
    And STDOUT should contain:
      """
      WordPress.WP.PostsPerPage.posts_per_page_posts_per_page
      """

    When I run the WP-CLI command `plugin check foo-sample`
    Then STDOUT should contain:
      """
      WordPress.WP.AlternativeFunctions.rand_mt_rand
      """
    And STDOUT should contain:
      """
      prohibited_text_detected
      """
    And STDOUT should contain:
      """
      WordPress.WP.PostsPerPage.posts_per_page_posts_per_page
      """

    When I run the WP-CLI command `plugin list-checks`
    Then STDOUT should contain:
      """
      prohibited_text
      """
    And STDOUT should contain:
      """
      postsperpage
      """

    When I run the WP-CLI command `plugin check foo-sample --format=csv --fields=code,severity --severity=4`
    Then STDOUT should contain:
      """
      WordPress.WP.AlternativeFunctions.rand_mt_rand,5
      """
    And STDOUT should contain:
      """
      prohibited_text_detected,8
      """
    And STDOUT should contain:
      """
      WordPress.WP.PostsPerPage.posts_per_page_posts_per_page,9
      """

    When I run the WP-CLI command `plugin check foo-sample --format=csv --fields=code,severity --severity=8`
    Then STDOUT should contain:
      """
      prohibited_text_detected,8
      """
    And STDOUT should contain:
      """
      WordPress.WP.PostsPerPage.posts_per_page_posts_per_page,9
      """
    And STDOUT should not contain:
      """
      WordPress.WP.AlternativeFunctions.rand_mt_rand,5
      """

    When I run the WP-CLI command `plugin check foo-sample --format=csv --fields=code,severity --severity=9`
    Then STDOUT should contain:
      """
      WordPress.WP.PostsPerPage.posts_per_page_posts_per_page,9
      """
    And STDOUT should not contain:
      """
      WordPress.WP.AlternativeFunctions.rand_mt_rand,5
      """
    And STDOUT should not contain:
      """
      prohibited_text_detected,8
      """

    When I run the WP-CLI command `plugin check foo-sample --severity=10`
    Then STDOUT should be empty
