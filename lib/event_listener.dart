abstract class EventListener {
  onAdLoaded(String configId);

  onAdDisplayed(String configId);

  onAdFailed(String errorMessage);

  onAdClicked(String configId);

  onAdUrlClicked(String configId);

  onAdClosed(String configId);
}
