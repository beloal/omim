package com.mopub.nativeads;

import android.support.annotation.NonNull;
import android.view.View;

public interface AdDelegate
{
  void registerView(@NonNull BaseNativeAd ad, @NonNull View view);
  void unregisterView(@NonNull BaseNativeAd ad, @NonNull View view);
}
