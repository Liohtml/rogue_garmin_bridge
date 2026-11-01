import com.garmin.connectiq.common.devices.*;
import java.io.*;
import java.lang.reflect.*;
import java.nio.file.*;
import java.util.*;

public class GenerateDevices {
    static Object f(Object o, String name) throws Exception {
        Class<?> c = o.getClass();
        while (c != null) {
            try { Field fl = c.getDeclaredField(name); fl.setAccessible(true); return fl.get(o); }
            catch (NoSuchFieldException e) { c = c.getSuperclass(); }
        }
        throw new NoSuchFieldException(name);
    }
    static String q(String s) {
        StringBuilder b = new StringBuilder("\"");
        for (char ch : s.toCharArray()) {
            if (ch == '"' || ch == '\\') b.append('\\').append(ch);
            else if (ch < 0x20 || ch > 0x7e) b.append(String.format("\\u%04x", (int) ch));
            else b.append(ch);
        }
        return b.append('"').toString();
    }
    public static void main(String[] a) throws Exception {
        DevicesXmlReader r = new DevicesXmlReader();
        r.read(new FileInputStream(a[0]));
        String outRoot = a[1];
        String prefix = a[2]; // regex
        for (Map.Entry<String, Device> e : r.getDeviceMap().entrySet()) {
            String id = e.getKey();
            if (!id.matches(prefix)) continue;
            Device d = e.getValue();
            StringBuilder s = new StringBuilder("{\n");
            s.append(" \"deviceId\": ").append(q(id)).append(",\n");
            s.append(" \"displayName\": ").append(q(d.getName())).append(",\n");
            s.append(" \"deviceFamily\": ").append(q(d.getDeviceFamilyId())).append(",\n");
            s.append(" \"worldWidePartNumber\": ").append(q(d.getWorldwidePartNumber())).append(",\n");
            s.append(" \"partNumbers\": [");
            boolean first = true;
            for (Device.PartNumberContext p : d.getPartNumbers().values()) {
                if (!first) s.append(","); first = false;
                s.append("\n  {\"number\": ").append(q(p.getPartNumber()));
                s.append(", \"connectIQVersion\": ").append(q(p.getConnectIQVersion().toString()));
                if (p.getMinFirmwareVersion() != null) s.append(", \"firmwareVersion\": ").append(p.getMinFirmwareVersion() & 0xFFFF);
                if (p.getSupportedAPIAnnotations() != null) {
                    s.append(", \"supportedAPIAnnotations\": [");
                    StringJoiner j = new StringJoiner(",");
                    for (String an : p.getSupportedAPIAnnotations()) j.add(q(an));
                    s.append(j).append("]");
                }
                @SuppressWarnings("unchecked") Set<String> fonts = (Set<String>) f(p, "mFontSet");
                String fs = fonts.isEmpty() ? "ww" : fonts.iterator().next();
                s.append(", \"languages\": [");
                StringJoiner j = new StringJoiner(",");
                for (String l : p.getLanguages()) j.add("{\"code\": " + q(l) + ", \"fontSet\": " + q(fs) + "}");
                s.append(j).append("]}");
            }
            s.append("\n ],\n");
            s.append(" \"orientation\": ").append(d.getOrientation().getOrientation()).append(",\n");
            s.append(" \"bitsPerPixel\": ").append(d.getBitsPerPixel()).append(",\n");
            Device.Resolution res = d.getScreenResolution();
            s.append(" \"resolution\": {\"width\": ").append(res.getWidth()).append(", \"height\": ").append(res.getHeight()).append("},\n");
            @SuppressWarnings("unchecked") List<Device.Color> pal = (List<Device.Color>) f(d, "mPalette");
            if (pal != null && !pal.isEmpty()) {
                s.append(" \"palette\": {\"colors\": [");
                StringJoiner j = new StringJoiner(",");
                for (Device.Color c : pal) {
                    if (c.getAlpha() == 0) j.add("\"TRANSPARENT\"");
                    else j.add(q(String.format("%02X%02X%02X", c.getRed(), c.getGreen(), c.getBlue())));
                }
                s.append(j).append("]},\n");
            }
            s.append(" \"appTypes\": [");
            StringJoiner j = new StringJoiner(",");
            for (Device.AppTypeContext at : d.getSupportedAppTypeContexts()) {
                j.add("\n  {\"type\": " + q(at.getAppType().getJsonAppType()) + ", \"memoryLimit\": " + at.getMemoryLimit() + ", \"prgLimit\": " + at.getPrgLimit() + "}");
            }
            s.append(j).append("\n ],\n");
            if (d.getLauncherIcon() != null) s.append(" \"launcherIcon\": {\"width\": ").append(d.getLauncherIcon().getWidth()).append(", \"height\": ").append(d.getLauncherIcon().getHeight()).append("},\n");
            if (d.getComplicationIcon() != null) s.append(" \"complicationIcon\": {\"width\": ").append(d.getComplicationIcon().getWidth()).append(", \"height\": ").append(d.getComplicationIcon().getHeight()).append("},\n");
            Device.PixelFormat pf = (Device.PixelFormat) f(d, "mPixelFormat");
            if (pf != null && pf != Device.PixelFormat.DEFAULT) s.append(" \"pixelFormat\": ").append(q(pf.name())).append(",\n");
            Object ocs = f(d, "mOutputColorSpace");
            if (ocs != null) s.append(" \"outputColorSpace\": ").append(q(((Enum<?>) ocs).name())).append(",\n");
            s.append(" \"menuBar\": {\"location\": {\"height\": ").append(d.getMenuBarHeight()).append("}},\n");
            s.append(" \"antiAliasedFontSupport\": ").append(d.supportsAntiAliasedFonts()).append(",\n");
            s.append(" \"screenRotationSupport\": ").append(d.supportsOrientationChange()).append(",\n");
            s.append(" \"alphaBlendingSupport\": ").append(d.supportsAlphaBlending()).append(",\n");
            List<?> imf = d.getImageFormats();
            if (imf != null) {
                s.append(" \"imageFormats\": [");
                StringJoiner k = new StringJoiner(",");
                for (Object o : imf) k.add(q((String) f(o, "mFormat")));
                s.append(k).append("],\n");
            }
            s.append(" \"gpuSupport\": ").append(d.supportsGPU()).append(",\n");
            s.append(" \"exportSupport\": ").append(d.supportsExport()).append(",\n");
            s.append(" \"controlBarSupport\": ").append(d.supportsControlBar()).append(",\n");
            if (d.getDeviceVersion() != null) s.append(" \"deviceVersion\": ").append(q(d.getDeviceVersion())).append(",\n");
            s.append(" \"codePageSize\": ").append(d.getCodePageSize()).append("\n}\n");
            Path dir = Paths.get(outRoot, id);
            Files.createDirectories(dir);
            Files.write(dir.resolve("compiler.json"), s.toString().getBytes("UTF-8"));
            System.out.println(id + " -> " + d.getName() + " | " + d.getDeviceFamilyId() + " | " + d.getSupportedAppTypes());
        }
    }
}
