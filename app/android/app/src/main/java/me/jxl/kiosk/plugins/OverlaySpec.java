// SPDX-License-Identifier: Apache-2.0
package me.jxl.kiosk.plugins;

/** SDK 1, overlay. Where a native overlay sits and how big it is. Sizes and insets are in dp. */
public final class OverlaySpec {
    /** Size the overlay to its view's measured size. */
    public static final int WRAP = -1;
    /** Fill the kiosk area, less the inset. */
    public static final int FILL = -2;

    public static final String TOP_LEFT = "top-left";
    public static final String TOP = "top";
    public static final String TOP_RIGHT = "top-right";
    public static final String LEFT = "left";
    public static final String CENTER = "center";
    public static final String RIGHT = "right";
    public static final String BOTTOM_LEFT = "bottom-left";
    public static final String BOTTOM = "bottom";
    public static final String BOTTOM_RIGHT = "bottom-right";

    /** Transitions for enter and exit. NONE shows and removes the overlay at once. */
    public static final String NONE = "none";
    /** Fades in or out. */
    public static final String FADE = "fade";
    /** Slides in from, or out to, the edge of its anchor while it fades. A centered overlay rises a little. */
    public static final String SLIDE = "slide";
    /** Grows in from, or shrinks out to, a slightly smaller size while it fades. Suits a centered card. */
    public static final String SCALE = "scale";

    /** In the dashboard's plane: over the dashboard, under the KS pages and views, the menu and the screensaver. The default. */
    public static final String LAYER_DASHBOARD = "dashboard";
    /** Over every KS page and view, camera views included. Hidden while the screensaver or the menu is up. */
    public static final String LAYER_VIEWS = "views";
    /** The KS voice overlay's slot: over the screensaver, the menu and camera views. The same as onTop(true). */
    public static final String LAYER_TOP = "top";

    private String anchor = CENTER;
    private int width = WRAP;
    private int height = WRAP;
    private int insetLeft;
    private int insetTop;
    private int insetRight;
    private int insetBottom;
    private int offsetX;
    private int offsetY;
    private boolean closeOnOutsideTouch;
    private boolean passOutsideTouch;
    private String enter = NONE;
    private String exit = NONE;
    private int transitionDuration = 200;
    private boolean closeOnBack = true;
    private String layer = LAYER_DASHBOARD;
    private boolean touchable = true;

    /** A wrapped overlay at one of the anchor constants. */
    public static OverlaySpec at(String anchor) { return new OverlaySpec().anchor(anchor); }
    /** An overlay that covers the whole kiosk area. */
    public static OverlaySpec fullScreen() { return new OverlaySpec().size(FILL, FILL); }

    public OverlaySpec anchor(String anchor) { this.anchor = anchor; return this; }
    /** WRAP, FILL or 1 to 4096 dp for each side. */
    public OverlaySpec size(int width, int height) { this.width = width; this.height = height; return this; }
    /** The same distance from every kiosk edge, 0 to 4096 dp. */
    public OverlaySpec inset(int inset) { return inset(inset, inset, inset, inset); }
    /** A distance from each kiosk edge, 0 to 4096 dp, such as the depth of a bar to keep a menu clear of it. */
    public OverlaySpec inset(int left, int top, int right, int bottom) {
        this.insetLeft = left; this.insetTop = top; this.insetRight = right; this.insetBottom = bottom; return this;
    }
    /**
     * Moves the overlay from its anchored place, -4096 to 4096 dp. Positive x moves right and positive y moves down.
     * KS keeps the overlay inside the area its insets leave. With TOP_LEFT and no inset, the offset is the overlay's position.
     */
    public OverlaySpec offset(int x, int y) { this.offsetX = x; this.offsetY = y; return this; }
    /** A touch anywhere outside the overlay closes it and sends overlay.closed. Off by default. */
    public OverlaySpec closeOnOutsideTouch(boolean close) { this.closeOnOutsideTouch = close; return this; }
    /** With closeOnOutsideTouch, the touch that closes the overlay also reaches what is under it. Off by default, so the touch only closes. */
    public OverlaySpec passOutsideTouch(boolean pass) { this.passOutsideTouch = pass; return this; }
    /** How the overlay appears: NONE, FADE, SLIDE or SCALE. NONE by default. */
    public OverlaySpec enter(String transition) { this.enter = transition; return this; }
    /** How the overlay leaves when hidden, replaced or closed: NONE, FADE, SLIDE or SCALE. NONE by default. Its view stays until the transition ends. */
    public OverlaySpec exit(String transition) { this.exit = transition; return this; }
    /** Length of the enter and exit transitions, 50 to 1000 ms. 200 by default. */
    public OverlaySpec transitionDuration(int ms) { this.transitionDuration = ms; return this; }
    /** Back closes the overlay and sends overlay.closed. On by default. */
    public OverlaySpec closeOnBack(boolean closeOnBack) { this.closeOnBack = closeOnBack; return this; }
    /** Which layer the overlay draws in: LAYER_DASHBOARD, LAYER_VIEWS or LAYER_TOP. LAYER_DASHBOARD by default. */
    public OverlaySpec layer(String layer) { this.layer = layer; return this; }
    /** Draw where the KS voice overlay does: over the screensaver, the menu and camera views. Off by default. The same as layer(LAYER_TOP). */
    public OverlaySpec onTop(boolean onTop) {
        if (onTop) layer = LAYER_TOP;
        else if (LAYER_TOP.equals(layer)) layer = LAYER_DASHBOARD;
        return this;
    }
    /** Off makes the overlay visual only: every touch passes through to whatever is under it. On by default. */
    public OverlaySpec touchable(boolean touchable) { this.touchable = touchable; return this; }

    public String anchor() { return anchor; }
    public int width() { return width; }
    public int height() { return height; }
    /** The largest of the four insets. */
    public int inset() { return Math.max(Math.max(insetLeft, insetTop), Math.max(insetRight, insetBottom)); }
    public int insetLeft() { return insetLeft; }
    public int insetTop() { return insetTop; }
    public int insetRight() { return insetRight; }
    public int insetBottom() { return insetBottom; }
    public int offsetX() { return offsetX; }
    public int offsetY() { return offsetY; }
    public boolean closeOnOutsideTouch() { return closeOnOutsideTouch; }
    public boolean passOutsideTouch() { return passOutsideTouch; }
    public String enter() { return enter; }
    public String exit() { return exit; }
    public int transitionDuration() { return transitionDuration; }
    public boolean closeOnBack() { return closeOnBack; }
    public String layer() { return layer; }
    public boolean onTop() { return LAYER_TOP.equals(layer); }
    public boolean touchable() { return touchable; }
}
