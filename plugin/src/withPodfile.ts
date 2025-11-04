import { ConfigPlugin, withPodfile as withPodfileMod } from '@expo/config-plugins'

/**
 * Adds OneSignalXCFramework to the LiveActivity target in Podfile
 * This is required for OneSignal's cross-platform Live Activity support
 * Uses proper Expo config plugin approach instead of dangerous mod
 */
export const withPodfile: ConfigPlugin<{
  targetName: string
}> = (config, { targetName }) => {
  return withPodfileMod(config, (config) => {
    const podfileContent = config.modResults.contents;

    // Check if our target already exists
    const targetRegex = new RegExp(`target '${targetName}' do[\\s\\S]*?end`, 'm')
    
    if (targetRegex.test(podfileContent)) {
      console.log(`✅ ${targetName} target already exists in Podfile, skipping...`)
      return config
    }

    // Add the LiveActivity target with OneSignal dependency
    const targetConfig = `
target '${targetName}' do
  pod 'OneSignalXCFramework', '>= 5.0', '< 6.0'
  use_frameworks! :linkage => podfile_properties['ios.useFrameworks'].to_sym if podfile_properties['ios.useFrameworks']
end`

    // Find the last target block and add our target after it
    const lastTargetMatch = podfileContent.match(/target '[^']+' do[\\s\\S]*?end/g)
    
    if (lastTargetMatch && lastTargetMatch.length > 0) {
      const lastTarget = lastTargetMatch[lastTargetMatch.length - 1]
      const insertPosition = podfileContent.lastIndexOf(lastTarget) + lastTarget.length
      
      config.modResults.contents = 
        podfileContent.slice(0, insertPosition) + 
        targetConfig + 
        podfileContent.slice(insertPosition)
    } else {
      // Fallback: add before the final end
      const finalEndMatch = podfileContent.match(/\nend\s*$/)
      if (finalEndMatch) {
        const insertPosition = finalEndMatch.index!
        config.modResults.contents = 
          podfileContent.slice(0, insertPosition) + 
          targetConfig + '\n' +
          podfileContent.slice(insertPosition)
      }
    }

    console.log(`✅ Added OneSignal support to ${targetName} target in Podfile`)
    
    return config
  })
}