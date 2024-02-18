<?php
/*
Plugin Name: Tempo Media Player
Plugin URI: https://mariani.life
Description: This is a wrapper for the Tempo media player
Version: 1.0.2
Author: Gabriel Mariani
Author URI: https://mariani.life
*/

if (!function_exists('trace')) {
    function trace($message)
    {
        if (WP_DEBUG === true) {
            if (is_array($message) || is_object($message)) {
                error_log(print_r($message, true));
            } else {
                error_log($message);
            }
        }
    }
}

$plugin = plugin_basename(__FILE__);

// register_activation_hook($file, $function)
register_activation_hook(__FILE__, 'tempo_options_default');

if (is_admin()) {
    add_filter('plugin_action_links_$plugin', 'tempo_settings_link');
    add_action('admin_menu', 'tempo_admin_menu');
    add_action('admin_init', 'tempo_admin_init');
    add_action('admin_enqueue_scripts', 'tempo_admin_scripts');
} else {
    add_shortcode('tempo', 'tempo_shortcode');
    $options = get_option('tempo_options');
    if ($options['embed'] == 1) wp_enqueue_script('tempoSWFObject', plugins_url('/swfobject.js', __FILE__));
}

///////////
// Admin //
///////////

// Add settings link on plugin page
function tempo_settings_link($links)
{
    $settings_link = '<a href="options-general.php?page=tempo-media-player/tempo-media-player.php">Settings</a>';
    array_push($links, $settings_link);
    return $links;
}

function tempo_admin_scripts()
{
    wp_enqueue_script('tempoColorPicker', plugins_url('/jscolor.js', __FILE__));
}

// Options Menu
function tempo_admin_menu()
{
    add_options_page('Tempo Media Player Settings', 'Tempo Media Player', 'manage_options', __FILE__, 'tempo_options_create');
}

function tempo_admin_init()
{

    // register_setting( $option_group, $option_name, $sanitize_callback = '' )
    register_setting('tempo_plugin_options', 'tempo_options', 'tempo_validate_options');

    // create sections on the page
    // add_settings_section($id, $title, $callback, $page)
    add_settings_section('tempo_usage', 'Usage', 'tempo_main_text', __FILE__);

    add_settings_section('tempo_main', 'General Settings', '', __FILE__);

    // add_settings_field( $id, $title, $callback, $page, $section, $args );
    add_settings_field('tempo_no_flash', 'Flash Player not installed message', 'tempo_setting_content', __FILE__, 'tempo_main', array('noFlash', ''));
    add_settings_field('tempo_bg_color', 'Background Color', 'tempo_setting_color', __FILE__, 'tempo_main', array('bgColor', ''));
    add_settings_field('tempo_embed', 'Embed SWFObject?', 'tempo_setting_checkbox', __FILE__, 'tempo_main', array('embed', '', 'Disable checkbox if you already have the SWFObject.js included'));
}

function tempo_options_default()
{
    $tmp = get_option('tempo_options');
    if ((!is_array($tmp))) {
        $arr = array(
            "noFlash" => "<p><strong>Please upgrade your Flash Player</strong> This content requires Flash Player 9.0.115 or higher installed.</p><img src='http://wwwimages.adobe.com/www.adobe.com/images/shared/download_buttons/get_flash_player.gif' title='Get Flash Player' alt='Get Flash Player' />",
            "bgColor" => "#000000",
            "embed" => 1
        );
        update_option('tempo_options', $arr);
    }
}

// ************************************************************************************************************
// Callback functions

function tempo_options_create()
{
?>
    <div class="wrap">
        <?php screen_icon(); ?>
        <h2>Tempo Media Player Settings</h2>

        <form method="post" action="options.php">
            <?php settings_fields('tempo_plugin_options'); ?>
            <?php do_settings_sections(__FILE__); ?>
            <?php submit_button(); ?>
        </form>
    </div>
<?php
}

function tempo_main_text()
{
?>
    <p>To embed the media player use the <code>tempo</code> short code. Below is an example of what it looks like.</p>
    <pre style="background: none repeat scroll 0 0 #EAEAEA; padding:5px;"><code>[tempo width="480" height="320" poster="http://www.example.com/poster.png" src="http://www.example.com/movie.mp4" streamhost="rtmp://example.cloudfront.net:80/cfx/st"]</code></pre>
    <p>The following is a list of the available attributes you can use within the <code>tempo</code> shortcode.</p>
    <table>
        <tr>
            <td><code>height = a number</code></td>
            <td>Sets the height of the video player.</td>
        </tr>
        <tr>
            <td><code>width = a number</code></td>
            <td>Sets the width of the video player.</td>
        </tr>
        <tr>
            <td><code>buffer = a number</code></td>
            <td>Sets the number of seconds to buffer before playing.</td>
        </tr>
        <tr>
            <td><code>id = a unique id</code></td>
            <td>Sets the id of the SWF within the HTML. Set this if you want to reference via JavaScript.</td>
        </tr>
        <tr>
            <td><code>autoplay = true|false</code></td>
            <td>Initally sets the player to start playing as soon as it's loaded.</td>
        </tr>
        <tr>
            <td><code>loop = true|false</code></td>
            <td>Initally sets the player to loop the video after it's finished playing.</td>
        </tr>
        <tr>
            <td><code>muted = true|false</code></td>
            <td>Initally sets the player to be muted.</td>
        </tr>
        <tr>
            <td><code>controls = true|false</code></td>
            <td>Initally sets the player controls to be visible.</td>
        </tr>
        <tr>
            <td><code>poster = a valid URL</code></td>
            <td>This is the URL to an image you want displayed until the video is loaded.</td>
        </tr>
        <tr>
            <td><code>src = a valid URL</code></td>
            <td>This is the URL to the actual video.</td>
        </tr>
        <tr>
            <td><code>streamhost = a valid URL</code></td>
            <td>This is the URL to your RTMP server if you want to stream your video.</td>
        </tr>
    </table>
<?php
}

function tempo_setting_color($args)
{
    $options = get_option('tempo_options');
    echo '<label for="tempo_options[' . $args[0] . ']">' . $args[1];
    echo "<input name='tempo_options[" . $args[0] . "]' class='color {hash:true}' size='5' type='text' value='{$options[$args[0]]}' />";
    echo ' ' . $args[2] . '</label>';
}

function tempo_setting_content($args)
{
    $options = get_option('tempo_options');
    echo '<label for="tempo_options[' . $args[0] . ']">' . $args[1];
    echo "<textarea name='tempo_options[" . $args[0] . "]' class='small-text' cols='100' rows='5'>{$options[$args[0]]}</textarea>";
    echo ' ' . $args[2] . '</label>';
}

function tempo_setting_checkbox($args)
{
    $options = get_option('tempo_options');
    echo "<input name='tempo_options[" . $args[0] . "]' type='checkbox' value='1' " . checked(1, $options[$args[0]], false) . " />";
    echo '<label for="tempo_option_' . $args[0] . '"> ' . $args[1] . '</label>';
}

function tempo_validate_options($input)
{
    $arr = array(
        "noFlash" => "<p><strong>Please upgrade your Flash Player</strong> This content requires Flash Player 9.0.115 or higher installed.</p><img src='http://wwwimages.adobe.com/www.adobe.com/images/shared/download_buttons/get_flash_player.gif' title='Get Flash Player' alt='Get Flash Player' />",
        "bgColor" => "#000000",
        "embed" => 1
    );

    $valid['noFlash'] =  (isset($input['noFlash']) ? wp_kses($input['noFlash'], array('p' => array(), 'br' => array(), 'img' => array('src' => array(), 'title' => array(), 'alt' => array()), 'strong' => array())) : $arr['noFlash']);
    $valid['bgColor'] =  (isset($input['bgColor']) ? wp_kses($input['bgColor'], array()) : $arr['bgColor']);
    $valid['embed'] =  (isset($input['embed']) && 1 == $input['embed'] ? 1 : 0);
    return $valid;
}

////////////
// Plugin //
////////////
/*

Available settings
------------------
id = unique id
autoplay = true | false
buffer = 0
loop = true | false
muted = true | false
controls = true | false
poster = URL
src = URL
streamhost = URL

*/
// [tempo width="480" height="320" poster="http://media.w3.org/2010/05/sintel/poster.png" src="http://media.w3.org/2010/05/sintel/trailer.mp4"]
function tempo_shortcode($atts)
{
    // Defaults if none given
    if (!$atts['width']) $atts['width'] = '480';
    if (!$atts['height']) $atts['height'] = '320';

    $pluginURL = WP_PLUGIN_URL . '/tempo-media-player';
    $options = get_option('tempo_options');
    $div_id = $atts['id'] ? $atts['id'] : 'flashcontent' . substr(uniqid(rand(), true), 0, 4);
    $code = '<div id="' . $div_id . '" style="width:' . trim($atts['width']) . 'px; height:' . trim($atts['height']) . 'px;">' . $options['noFlash'] . '</div>';
    $code .= '<script type="text/javascript">';
    $code .= '<!-- // <![CDATA[' . PHP_EOL;
    $code .= 'var flashvars = {' . PHP_EOL;
    $code .= 'width:"' . trim($atts['width']) . '",' . PHP_EOL;
    $code .= 'height:"' . trim($atts['height']) . '",' . PHP_EOL;
    if ($atts['autoplay']) $code .= 'autoplay:"' . trim($atts['autoplay']) . '",' . PHP_EOL;
    if ($atts['buffer']) $code .= 'buffer:"' . trim($atts['buffer']) . '",' . PHP_EOL;
    if ($atts['loop']) $code .= 'loop:"' . trim($atts['loop']) . '",' . PHP_EOL;
    if ($atts['muted']) $code .= 'muted:"' . trim($atts['muted']) . '",' . PHP_EOL;
    if ($atts['controls']) $code .= 'controls:"' . trim($atts['controls']) . '",' . PHP_EOL;
    if ($atts['poster']) $code .= 'poster:"' . trim($atts['poster']) . '",' . PHP_EOL;
    if ($atts['src']) $code .= 'src:"' . trim($atts['src']) . '",' . PHP_EOL;
    if ($atts['streamhost']) $code .= 'streamhost:"' . trim($atts['streamhost']) . '"' . PHP_EOL;
    $code .= '};' . PHP_EOL;
    $code .= 'var params = {' . PHP_EOL;
    $code .= 'allowscriptaccess:"always",' . PHP_EOL;
    $code .= 'allowfullscreen:"true",' . PHP_EOL;
    $code .= 'wmode:"transparent",' . PHP_EOL;
    $code .= 'bgcolor:"' . $options['bgColor'] . '"' . PHP_EOL;
    $code .= '};' . PHP_EOL;
    $code .= 'var attributes = {' . PHP_EOL;
    $code .= 'id: "' . $div_id . '",' . PHP_EOL;
    $code .= 'name: "' . $div_id . '"' . PHP_EOL;
    $code .= '};' . PHP_EOL;
    $code .= 'swfobject.embedSWF("' . plugins_url('/tempo.swf', __FILE__) . '", "' . $div_id . '", "' . trim($atts['width']) . '", "' . trim($atts['height']) . '", "9.0.115", false, flashvars, params, attributes);' . PHP_EOL;
    $code .= '// ]]> -->' . PHP_EOL;
    $code .= '</script>';

    return $code;
}

?>