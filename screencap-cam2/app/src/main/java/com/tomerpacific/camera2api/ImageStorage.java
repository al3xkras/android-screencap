package com.tomerpacific.camera2api;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.Image;
import android.util.Log;

import com.homesoft.encoder.Muxer;

import org.jetbrains.annotations.NotNull;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintStream;
import java.nio.ByteBuffer;
import java.util.LinkedList;
import java.util.concurrent.ThreadLocalRandom;

public class ImageStorage {
    private final Context context;
    String TAG="save";
    public static final String STORAGE_DIR = "/images/";
    public static final int BUFFER_SIZE = 5;
    private final LinkedList<Bitmap> buffer = new LinkedList<>();
    private int skipped = 0;

    public ImageStorage(Context context) {
        this.context = context;
    }

    public void saveNext(@NotNull Image image) throws IOException, InterruptedException {
        if (image.getWidth()<=0 || image.getHeight()<=0){
            return;
        }
        Bitmap previous = getPreviousImage();
        Bitmap b = imageToBitmap(image);
        if (previous==null){
            buffer.addLast(b);
            return;
        }
        int cmp = compareImages(previous,b);
        if (skipped<30 && cmp<30){
            Log.d("img-save", "saveNext: images are similar; save skipped "+cmp);
            skipped++;
            return;
        }
        skipped=0;
        if (buffer.size()>=BUFFER_SIZE){
            dumpBufferAndClear();
        }
        buffer.addLast(b);
    }
    public Bitmap getPreviousImage(){
        return buffer.size()>0?buffer.getLast():null;
    }
    public void clearBuffer(){
        buffer.clear();
    }
    private void dumpBufferAndClear() throws IOException, InterruptedException {
        File f = File.createTempFile("temp",".mp4");
        try {
            Muxer muxer = new Muxer(context,f);
            muxer.mux(buffer,null);
        } catch (RuntimeException e){
            e.printStackTrace();
        }
        clearBuffer();
    }
    private int compareImages(Bitmap b1, Bitmap b2){

        int randX;
        int randY;
        int loopCount=Math.max(100,(b1.getWidth()*b1.getHeight()/100)%Integer.MAX_VALUE);

        double delta = 0;

        for (int i = 0; i < loopCount; i++) {
            randX= ThreadLocalRandom.current().nextInt(0,b1.getWidth());
            randY= ThreadLocalRandom.current().nextInt(0,b1.getHeight());
            int c1 = b1.getPixel(randX,randY);
            int c2 = b2.getPixel(randX,randY);
            delta += colorDelta(c1,c2);
        }

        Log.w(TAG, "compareImages: "+delta+" "+loopCount);
        return (int)(delta*100/loopCount);
    }

    private float colorDelta(int c, int c1){
        float r = ((c >> 16) & 0xff) / 255.0f;
        float g = ((c >>  8) & 0xff) / 255.0f;
        float b = ((c      ) & 0xff) / 255.0f;
        float r1 = ((c1 >> 16) & 0xff) / 255.0f;
        float g1 = ((c1 >>  8) & 0xff) / 255.0f;
        float b1 = ((c1      ) & 0xff) / 255.0f;

        float delta = 0;
        delta+=Math.abs(r-r1);
        delta+=Math.abs(g-g1);
        delta+=Math.abs(b-b1);
        return delta;
    }

    private Bitmap imageToBitmap(Image im){
        ByteBuffer bb1 = im.getPlanes()[0].getBuffer();
        byte[] bytes = new byte[bb1.capacity()];
        bb1.get(bytes);
        return BitmapFactory.decodeByteArray(bytes,0,bytes.length,null);
    }
}
