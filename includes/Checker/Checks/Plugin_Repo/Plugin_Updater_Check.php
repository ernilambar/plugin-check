<?php
/**
 * Class Plugin_Updater_Check.
 *
 * @package plugin-check
 */

namespace WordPress\Plugin_Check\Checker\Checks\Plugin_Repo;

use Exception;
use WordPress\Plugin_Check\Checker\Check_Categories;
use WordPress\Plugin_Check\Checker\Check_Result;
use WordPress\Plugin_Check\Checker\Checks\Abstract_File_Check;
use WordPress\Plugin_Check\Traits\Amend_Check_Result;
use WordPress\Plugin_Check\Traits\Stable_Check;

/**
 * Check to detect plugin updater.
 *
 * @since 1.0.0
 */
class Plugin_Updater_Check extends Abstract_File_Check {

	use Amend_Check_Result;
	use Stable_Check;

	const TYPE_PLUGIN_UPDATE_URI_HEADER = 1;
	const TYPE_PLUGIN_UPDATER_FILE      = 2;
	const TYPE_PLUGIN_UPDATERS          = 4;
	const TYPE_PLUGIN_UPDATER_ROUTINES  = 8;
	const TYPE_ALL                      = 15; // Same as all of the above with bitwise OR.

	/**
	 * Bitwise flags to control check behavior.
	 *
	 * @since 1.0.0
	 * @var int
	 */
	protected $flags = 0;

	/**
	 * Constructor.
	 *
	 * @since 1.0.0
	 *
	 * @param int $flags Bitwise flags to control check behavior.
	 */
	public function __construct( $flags = self::TYPE_ALL ) {
		$this->flags = $flags;
	}

	/**
	 * Gets the categories for the check.
	 *
	 * Every check must have at least one category.
	 *
	 * @since 1.0.0
	 *
	 * @return array The categories for the check.
	 */
	public function get_categories() {
		return array( Check_Categories::CATEGORY_PLUGIN_REPO );
	}

	/**
	 * Amends the given result by running the check on the given list of files.
	 *
	 * @since 1.0.0
	 *
	 * @param Check_Result $result The check result to amend, including the plugin context to check.
	 * @param array        $files  List of absolute file paths.
	 *
	 * @throws Exception Thrown when the check fails with a critical error (unrelated to any errors detected as part of
	 *                   the check).
	 */
	protected function check_files( Check_Result $result, array $files ) {
		$php_files = self::filter_files_by_extension( $files, 'php' );

		// Looks for "UpdateURI" in plugin header.
		if ( $this->flags & self::TYPE_PLUGIN_UPDATE_URI_HEADER ) {
			$this->look_for_update_uri_header( $result );
		}

		// Looks for special updater file.
		if ( $this->flags & self::TYPE_PLUGIN_UPDATER_FILE ) {
			$this->look_for_updater_file( $result, $php_files );
		}

		// Looks for plugin updater code in plugin files.
		if ( $this->flags & self::TYPE_PLUGIN_UPDATERS ) {
			$this->look_for_plugin_updaters( $result, $php_files );
		}

		// Looks for plugin updater routines in plugin files.
		if ( $this->flags & self::TYPE_PLUGIN_UPDATER_ROUTINES ) {
			$this->look_for_updater_routines( $result, $php_files );
		}
	}

	/**
	 * Looks for UpdateURI in plugin header and amends the given result with an error if found.
	 *
	 * @since 1.0.0
	 *
	 * @param Check_Result $result The check result to amend, including the plugin context to check.
	 */
	protected function look_for_update_uri_header( Check_Result $result ) {
		if ( ! function_exists( 'get_plugin_data' ) ) {
			require_once ABSPATH . 'wp-admin/includes/plugin.php';
		}

		$plugin_main_file = $result->plugin()->main_file();
		$plugin_header    = get_plugin_data( $plugin_main_file );
		if ( ! empty( $plugin_header['UpdateURI'] ) ) {
			$this->add_result_error_for_file(
				$result,
				__( '<strong>Including An Update Checker / Changing Updates functionality.</strong><br>Plugin Updater detected. Use of the Update URI header is not allowed in plugins hosted on WordPress.org.', 'plugin-check' ),
				'plugin_updater_detected',
				$plugin_main_file,
				0,
				0,
				'https://developer.wordpress.org/plugins/wordpress-org/common-issues/#update-checker',
				9
			);
		}
	}

	/**
	 * Looks for plugin updater file and amends the given result with an error if found.
	 *
	 * @since 1.0.0
	 *
	 * @param Check_Result $result    The check result to amend, including the plugin context to check.
	 * @param array        $php_files List of absolute PHP file paths.
	 */
	protected function look_for_updater_file( Check_Result $result, array $php_files ) {

		$plugin_update_files = self::filter_files_by_regex( $php_files, '/plugin-update-checker\.php$/' );

		if ( $plugin_update_files ) {
			foreach ( $plugin_update_files as $file ) {
				$this->add_result_error_for_file(
					$result,
					sprintf(
						/* translators: %s: The match updater file name. */
						__( '<strong>Plugin Updater detected.</strong><br>These are not permitted in WordPress.org hosted plugins. Detected: %s', 'plugin-check' ),
						basename( $file )
					),
					'plugin_updater_detected',
					$file,
					0,
					0,
					'https://developer.wordpress.org/plugins/wordpress-org/common-issues/#update-checker',
					9
				);
			}

			return;
		}

		$has_vendor_updater = false;

		$plugin_path = $result->plugin()->path();

		$file = '';

		if ( is_dir( $plugin_path . 'vendor/yahnis-elsts/plugin-update-checker' ) ) {
			$has_vendor_updater = true;
			$file = $plugin_path . 'vendor/yahnis-elsts/plugin-update-checker/plugin-update-checker.php';
		} elseif ( is_dir( $plugin_path . 'vendor/plugin-update-checker' ) ) {
			$has_vendor_updater = true;
			$file = $plugin_path . 'vendor/plugin-update-checker/plugin-update-checker.php';
		} elseif ( is_dir( $plugin_path . 'vendor/kernl/kernl-update-checker' ) ) {
			$has_vendor_updater = true;
			$file = $plugin_path . 'vendor/kernl/kernl-update-checker/kernl-update-checker.php';
		}

		if ( $has_vendor_updater ) {
			$this->add_result_error_for_file(
				$result,
				sprintf(
					/* translators: %s: The match updater file name. */
					__( '<strong>Plugin Updater detected.</strong><br>These are not permitted in WordPress.org hosted plugins. Detected: %s', 'plugin-check' ),
					basename( $file )
				),
				'plugin_updater_detected',
				$file,
				0,
				0,
				'https://developer.wordpress.org/plugins/wordpress-org/common-issues/#update-checker',
				9
			);
		}
	}

	/**
	 * Looks for plugin updater code in plugin files and amends the given result with an error if found.
	 *
	 * @since 1.0.0
	 *
	 * @param Check_Result $result    The check result to amend, including the plugin context to check.
	 * @param array        $php_files List of absolute PHP file paths.
	 */
	protected function look_for_plugin_updaters( Check_Result $result, array $php_files ) {

		$look_for_regex = array(
			'#\'plugin-update-checker\'#',
			'#WP_GitHub_Updater#',
			'#WPGitHubUpdater#',
			'#class [A-Z_]+_Plugin_Updater#i',
			'#updater\.\w+\.\w{2,5}#i',
			'#site_transient_update_plugins#',
		);

		foreach ( $look_for_regex as $regex ) {
			$matches      = array();
			$updater_file = self::file_preg_match( $regex, $php_files, $matches );
			if ( $updater_file ) {
				$this->add_result_error_for_file(
					$result,
					sprintf(
						/* translators: %s: The match updater file name. */
						__( '<strong>Plugin Updater detected.</strong><br>These are not permitted in WordPress.org hosted plugins. Detected: %s', 'plugin-check' ),
						esc_attr( $matches[0] )
					),
					'plugin_updater_detected',
					$updater_file,
					0,
					0,
					'',
					9
				);
			}
		}
	}

	/**
	 * Looks for plugin updater routines in plugin files and amends the given result with an error if found.
	 *
	 * @since 1.0.0
	 *
	 * @param Check_Result $result    The check result to amend, including the plugin context to check.
	 * @param array        $php_files List of absolute PHP file paths.
	 */
	protected function look_for_updater_routines( Check_Result $result, array $php_files ) {

		$look_for_regex = array(
			'#auto_update_plugin#',
			'#pre_set_site_transient_update_\w+#i',
			'#_site_transient_update_\w+#i',
		);

		foreach ( $look_for_regex as $regex ) {
			$matches      = array();
			$updater_file = self::file_preg_match( $regex, $php_files, $matches );
			if ( $updater_file ) {
				$this->add_result_warning_for_file(
					$result,
					sprintf(
						/* translators: %s: The match file name. */
						__( '<strong>Plugin Updater detected.</strong><br>Detected code which may be altering WordPress update routines. Detected: %s', 'plugin-check' ),
						esc_html( $matches[0] )
					),
					'update_modification_detected',
					$updater_file,
					0,
					0,
					'https://developer.wordpress.org/plugins/wordpress-org/common-issues/#update-checker',
					9
				);
			}
		}
	}

	/**
	 * Gets the description for the check.
	 *
	 * Every check must have a short description explaining what the check does.
	 *
	 * @since 1.1.0
	 *
	 * @return string Description.
	 */
	public function get_description(): string {
		return __( 'Prevents altering WordPress update routines or using custom updaters, which are not allowed on WordPress.org.', 'plugin-check' );
	}

	/**
	 * Gets the documentation URL for the check.
	 *
	 * Every check must have a URL with further information about the check.
	 *
	 * @since 1.1.0
	 *
	 * @return string The documentation URL.
	 */
	public function get_documentation_url(): string {
		return __( 'https://developer.wordpress.org/plugins/wordpress-org/detailed-plugin-guidelines/', 'plugin-check' );
	}
}
