import java.awt.image.BufferedImage;
import java.io.File;
import javax.imageio.ImageIO;

class CheckScreenshot {
    public static void main(String[] args) throws Exception {
        if (args.length != 3) {
            throw new IllegalArgumentException("Usage: java CheckScreenshot.java <png> <rgb-hex> <minimum-pixels>");
        }

        BufferedImage image = ImageIO.read(new File(args[0]));
        if (image == null) {
            throw new IllegalStateException("Screenshot is not a readable image");
        }

        int expected = Integer.parseInt(args[1], 16);
        int minimumPixels = Integer.parseInt(args[2]);
        int matchingPixels = 0;
        for (int y = 0; y < image.getHeight(); y++) {
            for (int x = 0; x < image.getWidth(); x++) {
                int rgb = image.getRGB(x, y);
                int red = (rgb >> 16) & 0xff;
                int green = (rgb >> 8) & 0xff;
                int blue = rgb & 0xff;
                if (Math.abs(red - ((expected >> 16) & 0xff)) <= 5
                        && Math.abs(green - ((expected >> 8) & 0xff)) <= 5
                        && Math.abs(blue - (expected & 0xff)) <= 5) {
                    matchingPixels++;
                }
            }
        }

        if (matchingPixels < minimumPixels) {
            throw new IllegalStateException(
                    "Expected color #" + args[1] + " is not visible: " + matchingPixels + " matching pixels");
        }
        System.out.println("Color #" + args[1] + " visible in screenshot: " + matchingPixels + " matching pixels");
    }
}
